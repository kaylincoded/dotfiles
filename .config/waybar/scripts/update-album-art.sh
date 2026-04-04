#!/bin/bash
# Keeps /tmp/waybar-album-art.png updated with current track's album art
# Uses playerctl --follow for instant updates on track change
# Fetches high-res art from MusicBrainz Cover Art Archive

ART_FILE="/tmp/waybar-album-art.png"
HIRES_CACHE_DIR="/tmp/waybar-album-art-cache"
FIFO="/tmp/waybar-album-art-fifo"

mkdir -p "$HIRES_CACHE_DIR"
rm -f "$FIFO"
mkfifo "$FIFO"

cleanup() {
    rm -f "$FIFO"
    kill "$PLAYERCTL_PID" "$HIRES_PID" 2>/dev/null
    exit
}
trap cleanup EXIT TERM INT

cache_key_for() {
    echo "${1}-${2}" | md5sum | cut -d' ' -f1
}

fetch_hires() {
    local artist="$1" album="$2"
    [[ -z "$artist" || -z "$album" ]] && return 1

    local cache_key cache_file
    cache_key=$(cache_key_for "$artist" "$album")
    cache_file="${HIRES_CACHE_DIR}/${cache_key}.png"

    # Use cached version if available
    if [[ -f "$cache_file" ]]; then
        cp "$cache_file" "${ART_FILE}.tmp" && mv "${ART_FILE}.tmp" "$ART_FILE"
        return 0
    fi

    # Query MusicBrainz for release MBIDs (try multiple, some have low-res uploads)
    local query mb_response mbids mbid
    query="artist:${artist} AND release:${album}"
    mb_response=$(curl -s -A "waybar-album-art/1.0 (https://github.com/kaylincoded/dotfiles)" \
        "https://musicbrainz.org/ws/2/release?query=$(printf '%s' "$query" | jq -sRr @uri)&fmt=json&limit=5" 2>/dev/null)

    mapfile -t mbids < <(echo "$mb_response" | jq -r '.releases[].id // empty' 2>/dev/null)
    [[ ${#mbids[@]} -eq 0 ]] && return 1

    # Try each release until we find a high-res cover (>500px wide)
    for mbid in "${mbids[@]}"; do
        if curl -s -f -L -o "${cache_file}.tmp" \
            "https://coverartarchive.org/release/${mbid}/front-1200" 2>/dev/null; then
            if file "${cache_file}.tmp" | grep -qi 'image'; then
                local width
                width=$(identify -format '%w' "${cache_file}.tmp" 2>/dev/null)
                if [[ -n "$width" && "$width" -gt 500 ]]; then
                    mv "${cache_file}.tmp" "$cache_file"
                    cp "$cache_file" "${ART_FILE}.tmp" && mv "${ART_FILE}.tmp" "$ART_FILE"
                    return 0
                fi
            fi
        fi
        rm -f "${cache_file}.tmp"
    done
    return 1
}

# Feed track changes into the FIFO
playerctl metadata --follow --format '{{artist}}	{{album}}	{{mpris:artUrl}}' > "$FIFO" 2>/dev/null &
PLAYERCTL_PID=$!
HIRES_PID=""

# Read from FIFO in the main shell so backgrounding works
while IFS=$'\t' read -r ARTIST ALBUM ART_URL; do
    # Kill any in-flight hires fetch from previous track
    if [[ -n "$HIRES_PID" ]] && kill -0 "$HIRES_PID" 2>/dev/null; then
        kill "$HIRES_PID" 2>/dev/null
        wait "$HIRES_PID" 2>/dev/null
    fi

    if [[ -z "$ART_URL" ]]; then
        rm -f "$ART_FILE"
        continue
    fi

    # Check hires cache first
    cache_key=$(cache_key_for "$ARTIST" "$ALBUM")
    if [[ -f "${HIRES_CACHE_DIR}/${cache_key}.png" ]]; then
        cp "${HIRES_CACHE_DIR}/${cache_key}.png" "${ART_FILE}.tmp" && mv "${ART_FILE}.tmp" "$ART_FILE"
        continue
    fi

    # Show MPRIS art immediately as placeholder
    if [[ "$ART_URL" == file://* ]]; then
        cp "${ART_URL#file://}" "${ART_FILE}.tmp" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
    elif [[ "$ART_URL" == http* ]]; then
        curl -s -o "${ART_FILE}.tmp" "$ART_URL" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
    fi

    # Fetch hires art in background (will overwrite placeholder when done)
    fetch_hires "$ARTIST" "$ALBUM" &
    HIRES_PID=$!
done < "$FIFO"
