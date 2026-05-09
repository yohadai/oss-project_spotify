#!/bin/bash

# ====================== Check Input File ======================
if [ $# -ne 1 ]; then
    echo "usage: $0 file"
    exit 1
fi

# ====================== Student Info ======================
echo "***********************OSS1 - Project1***********************"
echo "*                  StudentID : 12234138                     *"
echo "*                  Name : Ahn SiHyeong                      *"
echo "*************************************************************"

FILE=$1
if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE does not exist."
    exit 1
fi

# ====================== Main Menu Loop ======================
while true; do
    echo ""
    echo "[MENU]"
    echo "1. Search tracks by artist name and track name"
    echo "2. List top 5 tracks by popularity in a specific genre"
    echo "3. Show top 5 longest tracks by duration"
    echo "4. Merge duplicate tracks and combine genres"
    echo "5. Analyze tracks - count, avg danceability, energy, valence"
    echo "6. Quit"
    echo -n "Enter your COMMAND (1~6) : "
    read cmd

    case $cmd in
        1)
            echo -n "Enter an artist name to search: "
            read artist
            echo -n "Enter a track name to search: "
            read track

            # Case-insensitive search
	    printf "Serch results for \"$artist\"/\"$track\":\n\n"
	    printf "artist\ttrack_name\tenergy\ttempo\n"
            LC_ALL=C awk -v a="$artist" -v t="$track" '
            BEGIN { FS="\t"; IGNORECASE=1 }
	    tolower($2) == tolower(a) && tolower($4) == tolower(t) {
                printf "%s\t%s\t%s\t%s\n", $2, $4, $9, $18
            }' "$FILE"
            ;;

        2)
            echo -n "Enter a genre: "
            read genre

            echo "Top 5 tracks by popularity in \"$genre\":"

	    LC_ALL=C awk -v g="$genre" '
	    BEGIN { FS="\t" }
	    NR > 1 {
    		# 20번 컬럼 끝의 \r 제거
    	        genre_col = $20;
    	        sub(/\r/, "", genre_col);

    		# 대소문자 무시 비교
    	        if (tolower(genre_col) == tolower(g)) {
            	    # 출력 순서: $2(Artist), $4(Track), $5(Pop), $9(Energy), $17(valence)
               	    printf "%s\t%s\t%s\t%s\t%s\n", $2, $4, $5, $9, $17
   	        }
	    }' "$FILE" | sort -t$'\t' -k3,3nr | head -n 5
	    ;;

        3)
            echo "Top 5 longest tracks by duration:"
            # Deduplicate + convert ms to mm:ss + sort
            LC_ALL=C awk '
            BEGIN { FS="\t" }
            {
                key = $2 "|" $4
                if (!(key in seen)) {
                    seen[key] = 1
                    dur = $6
                    min = int(dur / 60000)
                    sec = int((dur % 60000) / 1000)
                    printf "%s|%s|%02d:%02d|%d\n", $2, $4, min, sec, dur
                }
            }' "$FILE" | sort -t'|' -k4,4nr | head -n 5 | 
            awk -F'|' '{printf "%s\t%s\t%s\n", $1, $2, $3}'
            ;;

        4)
            echo "Tracks appearing in multiple genres (top 5 by popularity):"
            LC_ALL=C awk '
            BEGIN { FS="\t" }
            {
	    # 20번 컬럼 끝의 \r 제거
            genre_col = $20;
            sub(/\r/, "", genre_col);

            key = $2 "|" $3 "|" $4
	    if (!(key in genres)) {
		genres[key] = genre_col
	    }
    	    else {
		genres[key] = genres[key] "|" genre_col
	    }
            pop[key] = $5
            artist[key] = $2
            track[key] = $4
	    count[key]++
            }
            END {
                for (k in genres) {
		    if (count[k] > 1) {
                    	printf "%s\t%s\t%s\t%s\n", track[k], artist[k], pop[k], genres[k]
	    	    }
                }
            }' "$FILE" | sort -t$'\t' -k3,3nr |
	    awk 'BEGIN { FS="\t" }{ printf "%s\t%s\t%s\n", $1, $2, $4 }' | head -n 5
            ;;

        5)
            echo -n "Enter minimum popularity threshold: "
            read thresh

            awk -v th="$thresh" '
            BEGIN { FS="\t"; count=0; sum_d=0; sum_e=0; sum_v=0 }
            {
                key = $2 "|" $4
                if (!(key in seen) && $5 >= th) {
                    seen[key] = 1
                    count++
                    sum_d += $8
                    sum_e += $9
                    sum_v += $17
                }
            }
            END {
                if (count == 0) count = 1
                printf "popularity >= %d tracks: %d\n", th, count
                printf "avg danceability: %.2f\n", sum_d/count
                printf "avg energy: %.2f\n", sum_e/count
                printf "avg valence: %.2f\n", sum_v/count
            }' "$FILE"
            ;;

        6)
            echo "Bye!"
            exit 0
            ;;

        *)
            echo "Invalid command. Please enter 1~6."
            ;;
    esac
done
