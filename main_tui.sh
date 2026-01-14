#!/bin/bash

# Whiptail TUI File Editor - Terminal Based Interface
# Note: This TUI version implements core features. Some advanced GUI features
# are simplified due to whiptail's terminal-based limitations.

# Renk ayarları
export NEWT_COLORS='
root=white,black
window=white,black
border=white,black
textbox=white,black
button=black,white
'

# Dosya tipi seçimi
file_type=$(whiptail --title "File Type Selection" --menu \
"Select the file type you want to work with:" 18 60 6 \
".txt" "Text files" \
".log" "Log files" \
".md" "Markdown files" \
".conf" "Configuration files" \
".csv" "CSV (Comma Separated)" \
".tsv" "TSV (Tab Separated)" \
3>&1 1>&2 2>&3)

# Çıkış kontrolü
if [ $? -ne 0 ] || [ -z "$file_type" ]; then
    exit 0
fi

# Dosya yolu girişi
selected_file=$(whiptail --title "File Selection" --inputbox \
"Enter the full path of the $file_type file:" 10 60 \
"/home/umutkctp/" 3>&1 1>&2 2>&3)

# Çıkış kontrolü
if [ $? -ne 0 ] || [ -z "$selected_file" ]; then
    exit 0
fi

# Dosya kontrolü
if [ ! -f "$selected_file" ]; then
    whiptail --title "Error" --msgbox \
"File not found: $selected_file" 8 60
    exit 1
fi

# Text dosyaları için işlem menüsü
if [[ "$file_type" == ".txt" || "$file_type" == ".log" || "$file_type" == ".md" || "$file_type" == ".conf" ]]; then
    
    while true; do
        operation=$(whiptail --title "Text File Operations - $(basename $selected_file)" --menu \
		"Choose an operation:" 20 70 10 \
		"1" "Print: All lines" \
		"2" "Print: All lines with numbers" \
		"3" "Print: Specific range of lines" \
		"4" "Search: Lines containing text" \
		"5" "Search: Lines by length" \
		"6" "Count: Total number of lines" \
		"7" "Count: Longest line" \
		"8" "Replace: All occurrences" \
		"9" "Delete: Pattern from file" \
		"0" "Exit" \
		3>&1 1>&2 2>&3)
	
        if [ $? -ne 0 ] || [ "$operation" == "0" ]; then
            break
        fi

        case $operation in
            1)
                # Print all lines
                output=$(awk '{print $0}' "$selected_file")
                whiptail --title "All Lines" --scrolltext --msgbox \
				"$output" 20 78
                ;;
            
            2)
                # Print all lines with numbers
                output=$(awk '{print NR, $0}' "$selected_file")
                whiptail --title "All Lines with Numbers" --scrolltext --msgbox \
				"$output" 20 78
                ;;
            
            3)
                # Print specific range
                border1=$(whiptail --title "Line Range" --inputbox \
				"Enter first line number:" 8 50 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$border1" ]; then
                    border2=$(whiptail --title "Line Range" --inputbox \
					"Enter last line number:" 8 50 3>&1 1>&2 2>&3)
                    
                if [ $? -eq 0 ] && [ -n "$border2" ]; then
                        output=$(awk -v b1="$border1" -v b2="$border2" \
						'NR>=b1 && NR<=b2 {print NR, $0}' "$selected_file")
                        whiptail --title "Lines $border1 to $border2" --scrolltext --msgbox \
						"$output" 20 78
                    fi
                fi
                ;;
            
            4)
                # Search for text
                search_text=$(whiptail --title "Search Text" --inputbox \
				"Enter text to search:" 8 60 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$search_text" ]; then
                    output=$(awk -v text="$search_text" \
					'index($0, text) {print NR, $0}' "$selected_file")
                    
                    if [ -z "$output" ]; then
                        whiptail --title "Search Result" --msgbox \
						"No lines found containing: $search_text" 8 60
                    else
                        whiptail --title "Lines containing: $search_text" --scrolltext --msgbox \
						"$output" 20 78
                    fi
                fi
                ;;
            
            5)
                # Search by length
                min_length=$(whiptail --title "Line Length Filter" --inputbox \
				"Enter minimum line length:" 8 50 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$min_length" ]; then
                    output=$(awk -v min="$min_length" \
					'length($0) >= min {print NR, "(" length($0) " chars):", $0}' "$selected_file")
                    
                    if [ -z "$output" ]; then
                        whiptail --title "Search Result" --msgbox \
						"No lines found with length >= $min_length" 8 60
                    else
                        whiptail --title "Lines with length >= $min_length" --scrolltext --msgbox \
						"$output" 20 78
                    fi
                fi
                ;;
            
            6)
                # Count lines
                output=$(awk 'END {print "Total number of lines: " NR}' "$selected_file")
                whiptail --title "Line Count" --msgbox "$output" 8 50
                ;;
            
            7)
                # Longest line
                output=$(awk '{if(length($0) > max) {max=length($0); line=$0; lineno=NR}} \
				END {print "Line number: " lineno "\nLength: " max " characters\n\nContent:\n" line}' "$selected_file")
                whiptail --title "Longest Line" --msgbox "$output" 15 70
                ;;
            
            8)
                # Replace all occurrences
                find_text=$(whiptail --title "Replace - Find" --inputbox \
				"Enter text to find:" 8 60 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$find_text" ]; then
                    replace_text=$(whiptail --title "Replace - Replace With" --inputbox \
					"Replace '$find_text' with:" 8 60 3>&1 1>&2 2>&3)
                    
                    if [ $? -eq 0 ]; then
                        output=$(sed "s/$find_text/$replace_text/g" "$selected_file")
                        whiptail --title "Replacement Preview" --scrolltext --msgbox \
						"Preview of replaced content:\n\n$output" 20 78
                        
                        # Ask to save
                        if whiptail --title "Save Changes" --yesno \
						"Do you want to save these changes to a new file?" 8 60; then
                            save_path=$(whiptail --title "Save File" --inputbox \
							"Enter path for the modified file:" 8 60 \
							"$selected_file.modified" 3>&1 1>&2 2>&3)
                            
                            if [ $? -eq 0 ] && [ -n "$save_path" ]; then
                                echo "$output" > "$save_path"
                                whiptail --title "Success" --msgbox \
								"File saved to:\n$save_path" 8 60
                            fi
                        fi
                    fi
                fi
                ;;
            
            9)
                # Delete pattern
                pattern=$(whiptail --title "Delete Pattern" --inputbox \
				"Enter pattern to delete (lines containing this will be removed):" 8 60 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$pattern" ]; then
                    output=$(sed "/$pattern/d" "$selected_file")
                    whiptail --title "Deletion Preview" --scrolltext --msgbox \
					"Preview (lines with '$pattern' removed):\n\n$output" 20 78
                    
                    # Ask to save
                    if whiptail --title "Save Changes" --yesno \
					"Do you want to save these changes to a new file?" 8 60; then
                        save_path=$(whiptail --title "Save File" --inputbox \
						"Enter path for the modified file:" 8 60 \
						"$selected_file.modified" 3>&1 1>&2 2>&3)
                        
                        if [ $? -eq 0 ] && [ -n "$save_path" ]; then
                            echo "$output" > "$save_path"
                            whiptail --title "Success" --msgbox \
							"File saved to:\n$save_path" 8 60
                        fi
                    fi
                fi
                ;;
        esac
    done

# CSV/TSV dosyaları için işlem menüsü
elif [[ "$file_type" == ".csv" || "$file_type" == ".tsv" ]]; then
    
    # Delimiter belirleme
    if [ "$file_type" == ".csv" ]; then
        delimiter=","
        type_name="CSV"
    else
        delimiter=$'\t'
        type_name="TSV"
    fi
    
    while true; do
        operation=$(whiptail --title "$type_name File Operations - $(basename $selected_file)" --menu \
		"Choose an operation:" 18 70 8 \
		"1" "Print: All lines" \
		"2" "Print: All lines with numbers" \
		"3" "Print: Specific range of lines" \
		"4" "Search: Lines containing text" \
		"5" "Count: Total number of lines" \
		"6" "Count: Longest line" \
		"7" "Replace: All occurrences" \
		"0" "Exit" \
		3>&1 1>&2 2>&3)

        if [ $? -ne 0 ] || [ "$operation" == "0" ]; then
            break
        fi

        case $operation in
            1)
                # Print all lines
                output=$(awk '{print $0}' "$selected_file")
                whiptail --title "All Lines" --scrolltext --msgbox \
				"$output" 20 78
                ;;
            
            2)
                # Print all lines with numbers
                output=$(awk '{print NR, $0}' "$selected_file")
                whiptail --title "All Lines with Numbers" --scrolltext --msgbox \
				"$output" 20 78
                ;;
            
            3)
                # Print specific range
                border1=$(whiptail --title "Line Range" --inputbox \
				"Enter first line number:" 8 50 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$border1" ]; then
                    border2=$(whiptail --title "Line Range" --inputbox \
					"Enter last line number:" 8 50 3>&1 1>&2 2>&3)
                    
                    if [ $? -eq 0 ] && [ -n "$border2" ]; then
                        output=$(awk -v b1="$border1" -v b2="$border2" \
						'NR>=b1 && NR<=b2 {print NR, $0}' "$selected_file")
                        whiptail --title "Lines $border1 to $border2" --scrolltext --msgbox \
						"$output" 20 78
                    fi
                fi
                ;;
            
            4)
                # Search for text
                search_text=$(whiptail --title "Search Text" --inputbox \
				"Enter text to search:" 8 60 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$search_text" ]; then
                    output=$(awk -v text="$search_text" \
					'index($0, text) {print NR, $0}' "$selected_file")
                    
                    if [ -z "$output" ]; then
                        whiptail --title "Search Result" --msgbox \
						"No lines found containing: $search_text" 8 60
                    else
                        whiptail --title "Lines containing: $search_text" --scrolltext --msgbox \
						"$output" 20 78
                    fi
                fi
                ;;
            
            5)
                # Count lines
                output=$(awk 'END {print "Total number of lines: " NR}' "$selected_file")
                whiptail --title "Line Count" --msgbox "$output" 8 50
                ;;
            
            6)
                # Longest line
                output=$(awk '{if(length($0) > max) {max=length($0); line=$0; lineno=NR}} \
				END {print "Line number: " lineno "\nLength: " max " characters\n\nContent:\n" line}' "$selected_file")
                whiptail --title "Longest Line" --msgbox "$output" 15 70
                ;;
            
            7)
                # Replace all occurrences
                find_text=$(whiptail --title "Replace - Find" --inputbox \
				"Enter text to find:" 8 60 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ] && [ -n "$find_text" ]; then
                    replace_text=$(whiptail --title "Replace - Replace With" --inputbox \
					"Replace '$find_text' with:" 8 60 3>&1 1>&2 2>&3)
                    
                    if [ $? -eq 0 ]; then
                        output=$(sed "s/$find_text/$replace_text/g" "$selected_file")
                        whiptail --title "Replacement Preview" --scrolltext --msgbox \
						"Preview of replaced content:\n\n$output" 20 78
                        
                        # Ask to save
                        if whiptail --title "Save Changes" --yesno \
						"Do you want to save these changes to a new file?" 8 60; then
                            save_path=$(whiptail --title "Save File" --inputbox \
							"Enter path for the modified file:" 8 60 \
							"$selected_file.modified" 3>&1 1>&2 2>&3)
                            
                            if [ $? -eq 0 ] && [ -n "$save_path" ]; then
                                echo "$output" > "$save_path"
                                whiptail --title "Success" --msgbox \
								"File saved to:\n$save_path" 8 60
                            fi
                        fi
                    fi
                fi
                ;;
        esac
    done

else
    whiptail --title "Error" --msgbox \
	"Invalid file type: $file_type" 8 50
    exit 1
fi

exit 0
