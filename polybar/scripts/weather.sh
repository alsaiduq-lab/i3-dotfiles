#!/bin/bash

# Configuration
API_KEY="a9befac38bdd67c4d26d28434fa6460c"
CITY_ID="5913490"  # Calgary, Canada

# URLs
CURRENT_URL="http://api.openweathermap.org/data/2.5/weather?id=$CITY_ID&appid=$API_KEY&units=metric"
FORECAST_URL="http://api.openweathermap.org/data/2.5/forecast?id=$CITY_ID&appid=$API_KEY&units=metric"

# Cache settings
CACHE_DIR="$HOME/.cache/polybar-weather"
CURRENT_CACHE="$CACHE_DIR/current_weather.json"
FORECAST_CACHE="$CACHE_DIR/forecast_weather.json"

mkdir -p "$CACHE_DIR"

# Weather icons mapping
declare -A weather_icons
weather_icons=(
    ["Clear"]="☀️"
    ["Clouds"]="☁️"
    ["Few clouds"]="🌤️"
    ["Scattered clouds"]="⛅"
    ["Broken clouds"]="🌥️"
    ["Overcast clouds"]="☁️"
    ["Shower rain"]="🌦️"
    ["Rain"]="🌧️"
    ["Thunderstorm"]="⛈️"
    ["Snow"]="❄️"
    ["Mist"]="🌫️"
    ["Smoke"]="🌫️"
    ["Haze"]="🌫️"
    ["Dust"]="🌫️"
    ["Fog"]="🌁"
    ["Sand"]="🌫️"
    ["Ash"]="🌋"
    ["Squall"]="🌬️"
    ["Tornado"]="🌪️"
    ["Drizzle"]="🌧️"
    ["Sleet"]="🌨️"
    ["Freezing rain"]="🌨️"
    ["Light rain"]="🌦️"
    ["Heavy intensity rain"]="🌧️"
    ["Light snow"]="🌨️"
    ["Heavy snow"]="❄️"
)

# Polybar colors
COLOR_NORMAL="%{F-}"
COLOR_TEMP="%{F#7aa2f7}"
COLOR_ICON="%{F#bb9af7}"

# Check if cache is older than 30 minutes
cache_is_old() {
    local cache_file=$1
    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    local age=$((current_time - file_time))
    [[ $age -gt 1800 ]]  # 1800 seconds = 30 minutes
}

# Update cache from API
update_cache() {
    local url=$1
    local cache_file=$2
    if curl -sf "$url" > "$cache_file.tmp"; then
        mv "$cache_file.tmp" "$cache_file"
    else
        echo "Error: Failed to fetch weather data"
        return 1
    fi
}

# Get wind direction
get_wind_direction() {
    local deg=$1
    
    if [ -z "$deg" ] || ! [[ "$deg" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "UNK"
        return
    fi

    local dir
    if (( $(echo "$deg >= 337.5" | bc -l) )) || (( $(echo "$deg < 22.5" | bc -l) )); then
        dir="N"
    elif (( $(echo "$deg >= 22.5" | bc -l) )) && (( $(echo "$deg < 67.5" | bc -l) )); then
        dir="NE"
    elif (( $(echo "$deg >= 67.5" | bc -l) )) && (( $(echo "$deg < 112.5" | bc -l) )); then
        dir="E"
    elif (( $(echo "$deg >= 112.5" | bc -l) )) && (( $(echo "$deg < 157.5" | bc -l) )); then
        dir="SE"
    elif (( $(echo "$deg >= 157.5" | bc -l) )) && (( $(echo "$deg < 202.5" | bc -l) )); then
        dir="S"
    elif (( $(echo "$deg >= 202.5" | bc -l) )) && (( $(echo "$deg < 247.5" | bc -l) )); then
        dir="SW"
    elif (( $(echo "$deg >= 247.5" | bc -l) )) && (( $(echo "$deg < 292.5" | bc -l) )); then
        dir="W"
    elif (( $(echo "$deg >= 292.5" | bc -l) )) && (( $(echo "$deg < 337.5" | bc -l) )); then
        dir="NW"
    else
        dir="UNK"
    fi
    echo "$dir"
}

# Update caches if needed
if [[ ! -f "$CURRENT_CACHE" ]] || cache_is_old "$CURRENT_CACHE"; then
    update_cache "$CURRENT_URL" "$CURRENT_CACHE"
fi
if [[ ! -f "$FORECAST_CACHE" ]] || cache_is_old "$FORECAST_CACHE"; then
    update_cache "$FORECAST_URL" "$FORECAST_CACHE"
fi

# Get current weather for polybar display
get_weather() {
    if [ ! -f "$CURRENT_CACHE" ]; then
        echo "%{F#f44336}No weather data%{F-}"
        return 1
    fi

    local weather_data=$(cat "$CURRENT_CACHE")
    if [ -z "$weather_data" ]; then
        echo "%{F#f44336}Invalid data%{F-}"
        return 1
    fi

    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].main')
    local weather_description=$(echo "$weather_data" | jq -r '.weather[0].description')
    local temperature=$(echo "$weather_data" | jq '.main.temp' | xargs printf "%.0f")
    local icon=${weather_icons[$weather_condition]:-${weather_icons[$weather_description]:-"❓"}}
    
    # Format for polybar with colors
    echo "${COLOR_ICON}${icon}${COLOR_NORMAL} ${COLOR_TEMP}${temperature}°C${COLOR_NORMAL}"
}

# Handle click events
handle_click() {
    local weather_data=$(cat "$CURRENT_CACHE")
    local desc=$(echo "$weather_data" | jq -r '.weather[0].description' | sed 's/\b\(.\)/\u\1/g')
    local temp=$(echo "$weather_data" | jq '.main.temp' | xargs printf "%.1f")
    local feels_like=$(echo "$weather_data" | jq '.main.feels_like' | xargs printf "%.1f")
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed' | xargs printf "%.1f")
    wind_speed=$(awk "BEGIN {printf \"%.1f\", $wind_speed * 3.6}")  # Convert m/s to km/h
    local wind_deg=$(echo "$weather_data" | jq '.wind.deg')
    local wind_dir=$(get_wind_direction "$wind_deg")
    
    notify-send "Weather in Calgary" "\
Condition: $desc
Temperature: ${temp}°C
Feels like: ${feels_like}°C
Humidity: ${humidity}%
Wind: ${wind_speed} km/h ${wind_dir}"
}

# Main execution
case "$1" in
    click)
        handle_click
        ;;
    refresh)
        update_cache "$CURRENT_URL" "$CURRENT_CACHE"
        update_cache "$FORECAST_URL" "$FORECAST_CACHE"
        get_weather
        ;;
    *)
        get_weather
        ;;
esac
