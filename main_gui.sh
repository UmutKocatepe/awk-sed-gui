#!/bin/bash

# Icon ayarları
export GTK_THEME=Adwaita

# Ana dosya seçim ekranı
array=$(yad --title=".txt, .csv file editor" --text="Welcome to File Editor" \
    --window-icon=gtk-edit \
    --form --field="What file type do you want to select:CB" .txt\!.log\!.md\!.conf\!.csv\!.tsv \
    --form --field="Select the file:SFL" /home/umutkctp \
    --width=450 --height=180)

# Çıkış kontrolü
if [ -z "$array" ]; then
    exit 0
fi

echo "${array[@]}"
selected_file_type="${array%%|*}"
echo "Selected file type: $selected_file_type"
selected_file="${array#*|}"
selected_file="${selected_file%|}"
echo "Selected file: $selected_file"

# Dosya kontrolü
if [ ! -f "$selected_file" ]; then
    yad --error --window-icon=dialog-error --image=dialog-error \
        --text="File not found: $selected_file" --width=300
    exit 1
fi

# Dosya tipine göre işlem seçenekleri
case "${selected_file_type}" in
    *.txt|*.log|*.md|*.conf)
        arrayTxt=$(yad --form --separator='|' --title="Text File Operations" \
            --window-icon=gtk-edit \
            --form --field="Print operations:CB" \none\!all\ \lines\!all\ \lines\ \with\ \number\!all\ \lines\ \with\ \specific\ \range\ \of\ \number \
            --form --field="Search/Filter operations:CB" \none\!lines\ \that\ \contain\ \your\ \text\!lines\ \with\ \length\ \which\ \greater\ \than\ \your\ \entered \
            --form --field="Count operations:CB" \none\!number\ \of\ \lines\!longest\ \line\ \of\ \the\ \file \
            --form --field="Replacement operations:CB" \none\!all\ \occurences\ \of\ \a\ \string\!occurences\ \of\ \a\ \string\ \from\ \specific\ \line\!occurences\ \of\ \a\ \string\ \from\ \a\ \specific\ \range\ \of\ \line\!occurences\ \from\ \nth\ \to\ \remaining \
            --form --field="Delete operations:CB" \none\!Delete\ \pattern\ \from\ \file\!Delete\ \trailing\ \spaces\!Delete\ \specific\ \line \
            --form --field="Insert operations:CB" \none\!Insert\ \line\ \before\ \specific\ \line\!Insert\ \line\ \after\ \specific\ \line \
            --width=550 --height=350)
        
        if [ -z "$arrayTxt" ]; then
            exit 0
        fi
        ;;
    *.csv|*.tsv)
        arrayCsv=$(yad --form --separator='|' --title="CSV/TSV File Operations" \
            --window-icon=x-office-spreadsheet \
            --form --field="Print operations:CB" \none\!all\ \lines\!all\ \lines\ \with\ \number\!all\ \lines\ \with\ \specific\ \range\ \of\ \number\!specific\ \columns\!specific\ \columns\ \with\ \custom\ \separator \
            --form --field="Search/Filter operations:CB" \none\!lines\ \that\ \contain\ \your\ \text\!lines\ \with\ \length\ \which\ \greater\ \than\ \your\ \entered\!lines\ \with\ \specific\ \column\ \value\!lines\ \where\ \column\ \matches\ \number \
            --form --field="Count operations:CB" \none\!number\ \of\ \lines\!longest\ \line\ \of\ \the\ \file \
            --form --field="Replacement operations:CB" \none\!all\ \occurences\ \of\ \a\ \string\!occurences\ \of\ \a\ \string\ \from\ \specific\ \line\!occurences\ \of\ \a\ \string\ \from\ \a\ \specific\ \range\ \of\ \line \
            --form --field="Delete operations:CB" \none\!Delete\ \pattern\ \from\ \file\!Delete\ \specific\ \line \
            --width=550 --height=320)
        
        if [ -z "$arrayCsv" ]; then
            exit 0
        fi
        ;;
    *) 
        yad --error --window-icon=dialog-error --image=dialog-error \
            --text="Invalid file type selected" --width=300
        exit 1
        ;;
esac

# Text dosyaları için işlemler
if [[ "$selected_file_type" == ".txt" || "$selected_file_type" == ".log" || "$selected_file_type" == ".md" || "$selected_file_type" == ".conf" ]]; then
    echo "${arrayTxt[@]}"
    IFS='|' read -r f1 f2 f3 f4 f5 f6 <<< "$arrayTxt"
    echo "Operations: Print=$f1 | Search=$f2 | Count=$f3 | Replace=$f4 | Delete=$f5 | Insert=$f6"

    # PRINT İŞLEMLERİ
    if [ "$f1" == "all lines" ]; then
        output=$(awk '{print $0}' "$selected_file")
        yad --text-info --title="All Lines" --window-icon=gtk-file \
            --text="$output" --width=700 --height=500
    
    elif [ "$f1" == "all lines with number" ]; then
        output=$(awk '{print NR, $0}' "$selected_file")
        yad --text-info --title="All Lines with Numbers" --window-icon=gtk-file \
            --text="$output" --width=700 --height=500
    
    elif [ "$f1" == "all lines with specific range of number" ]; then
        arrayRanges=$(yad --form --separator='|' --title="Line Range Selection" \
            --window-icon=gtk-find \
            --form --field="Enter first line number" \
            --form --field="Enter last line number" \
            --width=350)
        
        if [ -n "$arrayRanges" ]; then
            border1="${arrayRanges%%|*}"
            border2="${arrayRanges#*|}"
            border2="${border2%|}"
            output=$(awk -v b1="$border1" -v b2="$border2" 'NR>=b1 && NR<=b2 {print NR, $0}' "$selected_file")
            yad --text-info --title="Lines $border1 to $border2" --window-icon=gtk-file \
                --text="$output" --width=700 --height=500
        fi
    fi

    # SEARCH/FILTER İŞLEMLERİ
    if [ "$f2" == "lines that contain your text" ]; then
        arrayText=$(yad --form --separator='|' --title="Search Text" \
            --window-icon=gtk-find \
            --form --field="Enter your text to search" \
            --width=350)
        
        if [ -n "$arrayText" ]; then
            inputText="${arrayText%|}"
            echo "Searching for: $inputText"
            output=$(awk -v text="$inputText" 'index($0, text) {print NR, $0}' "$selected_file")
            yad --text-info --title="Lines containing: $inputText" --window-icon=gtk-find \
                --text="$output" --width=700 --height=500
        fi
    
    elif [ "$f2" == "lines with length which greater than or equal your entered" ]; then
        arrayLength=$(yad --form --separator='|' --title="Line Length Filter" \
            --window-icon=gtk-find \
            --form --field="Enter minimum line length" \
            --width=350)
        
        if [ -n "$arrayLength" ]; then
            inputLength="${arrayLength%|}"
            echo "Min length: $inputLength"
            output=$(awk -v min="$inputLength" 'length($0) >= min {print NR, length($0), $0}' "$selected_file")
            yad --text-info --title="Lines with length >= $inputLength" --window-icon=gtk-find \
                --text="$output" --width=700 --height=500
        fi
    fi

    # COUNT İŞLEMLERİ
    if [ "$f3" == "number of lines" ]; then
        output=$(awk 'END {print "Total number of lines:", NR}' "$selected_file")
        yad --info --window-icon=dialog-information --image=dialog-information \
            --text="$output" --width=300 --height=120
    
    elif [ "$f3" == "longest line of the file" ]; then
        output=$(awk '{if(length($0) > max) {max=length($0); line=$0; lineno=NR}} END {print "Line number:", lineno, "\nLength:", max, "\nContent:", line}' "$selected_file")
        yad --info --window-icon=dialog-information --image=dialog-information \
            --text="$output" --width=600 --height=200
    fi

    # REPLACEMENT İŞLEMLERİ
    if [ "$f4" == "all occurences of a string" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace All Occurrences" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText <<< "$arrayReplace"
            replaceText="${replaceText%|}"
            output=$(sed "s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced: $findText -> $replaceText" --window-icon=gtk-find-and-replace \
                --text="$output" --width=700 --height=500 \
                --button="gtk-save:0" --button="gtk-close:1"
            
            if [ $? -eq 0 ]; then
                savePath=$(yad --file-selection --save --title="Save modified file" \
                    --window-icon=gtk-save \
                    --filename="$selected_file.modified")
                if [ -n "$savePath" ]; then
                    echo "$output" > "$savePath"
                    yad --info --window-icon=dialog-information --image=dialog-information \
                        --text="File saved to: $savePath" --width=300
                fi
            fi
        fi
    
    elif [ "$f4" == "occurences of a string from specific line" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace from Specific Line" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --form --field="Line number" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText lineNum <<< "$arrayReplace"
            lineNum="${lineNum%|}"
            output=$(sed "${lineNum}s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced in line $lineNum" --window-icon=gtk-find-and-replace \
                --text="$output" --width=700 --height=500
        fi
    
    elif [ "$f4" == "occurences of a string from a specific range of line" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace in Line Range" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --form --field="From line number" \
            --form --field="To line number" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText fromLine toLine <<< "$arrayReplace"
            toLine="${toLine%|}"
            output=$(sed "${fromLine},${toLine}s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced in lines $fromLine-$toLine" --window-icon=gtk-find-and-replace \
                --text="$output" --width=700 --height=500
        fi
    
    elif [ "$f4" == "occurences from nth to remaining" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace nth to End" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --form --field="Starting from occurrence number" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText nthOcc <<< "$arrayReplace"
            nthOcc="${nthOcc%|}"
            output=$(sed "s/$findText/$replaceText/${nthOcc}g" "$selected_file")
            yad --text-info --title="Replaced from ${nthOcc}th occurrence" --window-icon=gtk-find-and-replace \
                --text="$output" --width=700 --height=500
        fi
    fi

    # DELETE İŞLEMLERİ
    if [ "$f5" == "Delete pattern from file" ]; then
        arrayPattern=$(yad --form --separator='|' --title="Delete Pattern" \
            --window-icon=gtk-delete \
            --form --field="Enter pattern to delete" \
            --width=350)
        
        if [ -n "$arrayPattern" ]; then
            pattern="${arrayPattern%|}"
            output=$(sed "/$pattern/d" "$selected_file")
            yad --text-info --title="Lines with pattern '$pattern' deleted" --window-icon=gtk-delete \
                --text="$output" --width=700 --height=500 \
                --button="gtk-save:0" --button="gtk-close:1"
            
            if [ $? -eq 0 ]; then
                savePath=$(yad --file-selection --save --title="Save modified file" \
                    --window-icon=gtk-save \
                    --filename="$selected_file.modified")
                if [ -n "$savePath" ]; then
                    echo "$output" > "$savePath"
                    yad --info --window-icon=dialog-information --image=dialog-information \
                        --text="File saved to: $savePath" --width=300
                fi
            fi
        fi
    
    elif [ "$f5" == "Delete trailing spaces" ]; then
        output=$(sed 's/[[:space:]]*$//' "$selected_file")
        yad --text-info --title="Trailing Spaces Deleted" --window-icon=gtk-delete \
            --text="$output" --width=700 --height=500 \
            --button="gtk-save:0" --button="gtk-close:1"
        
        if [ $? -eq 0 ]; then
            savePath=$(yad --file-selection --save --title="Save modified file" \
                --window-icon=gtk-save \
                --filename="$selected_file.modified")
            if [ -n "$savePath" ]; then
                echo "$output" > "$savePath"
                yad --info --window-icon=dialog-information --image=dialog-information \
                    --text="File saved to: $savePath" --width=300
            fi
        fi
    
    elif [ "$f5" == "Delete specific line" ]; then
        arrayLineNum=$(yad --form --separator='|' --title="Delete Line" \
            --window-icon=gtk-delete \
            --form --field="Enter line number to delete" \
            --width=350)
        
        if [ -n "$arrayLineNum" ]; then
            lineNum="${arrayLineNum%|}"
            output=$(sed "${lineNum}d" "$selected_file")
            yad --text-info --title="Line $lineNum deleted" --window-icon=gtk-delete \
                --text="$output" --width=700 --height=500
        fi
    fi

    # INSERT İŞLEMLERİ
    if [ "$f6" == "Insert line before specific line" ]; then
        arrayInsert=$(yad --form --separator='|' --title="Insert Line Before" \
            --window-icon=gtk-add \
            --form --field="Line number to insert before" \
            --form --field="Text to insert" \
            --width=350 --height=130)
        
        if [ -n "$arrayInsert" ]; then
            IFS='|' read -r lineNum insertText <<< "$arrayInsert"
            insertText="${insertText%|}"
            output=$(sed "${lineNum}i\\${insertText}" "$selected_file")
            yad --text-info --title="Line inserted before line $lineNum" --window-icon=gtk-add \
                --text="$output" --width=700 --height=500
        fi
    
    elif [ "$f6" == "Insert line after specific line" ]; then
        arrayInsert=$(yad --form --separator='|' --title="Insert Line After" \
            --window-icon=gtk-add \
            --form --field="Line number to insert after" \
            --form --field="Text to insert" \
            --width=350 --height=130)
        
        if [ -n "$arrayInsert" ]; then
            IFS='|' read -r lineNum insertText <<< "$arrayInsert"
            insertText="${insertText%|}"
            output=$(sed "${lineNum}a\\${insertText}" "$selected_file")
            yad --text-info --title="Line inserted after line $lineNum" --window-icon=gtk-add \
                --text="$output" --width=700 --height=500
        fi
    fi

# CSV/TSV dosyaları için işlemler
elif [[ "$selected_file_type" == ".csv" || "$selected_file_type" == ".tsv" ]]; then
    echo "${arrayCsv[@]}"
    IFS='|' read -r f1 f2 f3 f4 f5 <<< "$arrayCsv"
    echo "CSV/TSV Operations: Print=$f1 | Search=$f2 | Count=$f3 | Replace=$f4 | Delete=$f5"
    
    # Delimiter belirleme
    if [ "$selected_file_type" == ".csv" ]; then
        delimiter=","
    else
        delimiter="\t"
    fi

    # PRINT İŞLEMLERİ - CSV/TSV
    if [ "$f1" == "all lines" ]; then
        output=$(awk '{print $0}' "$selected_file")
        yad --text-info --title="All Lines" --window-icon=x-office-spreadsheet \
            --text="$output" --width=750 --height=500
    
    elif [ "$f1" == "all lines with number" ]; then
        output=$(awk '{print NR, $0}' "$selected_file")
        yad --text-info --title="All Lines with Numbers" --window-icon=x-office-spreadsheet \
            --text="$output" --width=750 --height=500
    
    elif [ "$f1" == "all lines with specific range of number" ]; then
        arrayRanges=$(yad --form --separator='|' --title="Line Range Selection" \
            --window-icon=gtk-find \
            --form --field="Enter first line number" \
            --form --field="Enter last line number" \
            --width=350)
        
        if [ -n "$arrayRanges" ]; then
            border1="${arrayRanges%%|*}"
            border2="${arrayRanges#*|}"
            border2="${border2%|}"
            output=$(awk -v b1="$border1" -v b2="$border2" 'NR>=b1 && NR<=b2 {print NR, $0}' "$selected_file")
            yad --text-info --title="Lines $border1 to $border2" --window-icon=x-office-spreadsheet \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f1" == "specific columns" ]; then
        arrayColumns=$(yad --form --separator='|' --title="Select Columns" \
            --window-icon=x-office-spreadsheet \
            --form --field="Enter column numbers (space-separated, e.g., 1 3 5)" \
            --width=450)
        
        if [ -n "$arrayColumns" ]; then
            columns="${arrayColumns%|}"
            awkCmd='{print '
            for col in $columns; do
                awkCmd+='$'$col'" "'
            done
            awkCmd+='}'
            
            output=$(awk -F"$delimiter" "$awkCmd" "$selected_file")
            yad --text-info --title="Selected Columns: $columns" --window-icon=x-office-spreadsheet \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f1" == "specific columns with custom separator" ]; then
        arrayCustom=$(yad --form --separator='|' --title="Custom Column Display" \
            --window-icon=x-office-spreadsheet \
            --form --field="Enter column numbers (space-separated, e.g., 1 3 5)" \
            --form --field="Enter output separator (e.g., | or tab)" \
            --width=450)
        
        if [ -n "$arrayCustom" ]; then
            IFS='|' read -r columns customSep <<< "$arrayCustom"
            customSep="${customSep%|}"
            
            awkCmd='{OFS="'$customSep'"; print '
            first=true
            for col in $columns; do
                if [ "$first" = true ]; then
                    awkCmd+='$'$col
                    first=false
                else
                    awkCmd+=', $'$col
                fi
            done
            awkCmd+='}'
            
            output=$(awk -F"$delimiter" "$awkCmd" "$selected_file")
            yad --text-info --title="Columns $columns with separator '$customSep'" --window-icon=x-office-spreadsheet \
                --text="$output" --width=750 --height=500
        fi
    fi

    # SEARCH/FILTER İŞLEMLERİ - CSV/TSV
    if [ "$f2" == "lines that contain your text" ]; then
        arrayText=$(yad --form --separator='|' --title="Search Text" \
            --window-icon=gtk-find \
            --form --field="Enter text to search" \
            --width=350)
        
        if [ -n "$arrayText" ]; then
            inputText="${arrayText%|}"
            output=$(awk -v text="$inputText" 'index($0, text) {print NR, $0}' "$selected_file")
            yad --text-info --title="Lines containing: $inputText" --window-icon=gtk-find \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f2" == "lines with length which greater than or equal your entered" ]; then
        arrayLength=$(yad --form --separator='|' --title="Line Length Filter" \
            --window-icon=gtk-find \
            --form --field="Enter minimum line length" \
            --width=350)
        
        if [ -n "$arrayLength" ]; then
            inputLength="${arrayLength%|}"
            output=$(awk -v min="$inputLength" 'length($0) >= min {print NR, length($0), $0}' "$selected_file")
            yad --text-info --title="Lines with length >= $inputLength" --window-icon=gtk-find \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f2" == "lines with specific column value" ]; then
        arrayColSearch=$(yad --form --separator='|' --title="Search in Column" \
            --window-icon=gtk-find \
            --form --field="Enter column number" \
            --form --field="Enter value to search" \
            --width=350)
        
        if [ -n "$arrayColSearch" ]; then
            IFS='|' read -r colNum searchValue <<< "$arrayColSearch"
            searchValue="${searchValue%|}"
            output=$(awk -F"$delimiter" -v col="$colNum" -v val="$searchValue" '$col == val {print NR, $0}' "$selected_file")
            yad --text-info --title="Lines where column $colNum = $searchValue" --window-icon=gtk-find \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f2" == "lines where column matches number" ]; then
        arrayColNum=$(yad --form --separator='|' --title="Numeric Column Filter" \
            --window-icon=gtk-find \
            --form --field="Enter column number" \
            --form --field="Enter line number" \
            --width=350)
        
        if [ -n "$arrayColNum" ]; then
            IFS='|' read -r colNum lineNum <<< "$arrayColNum"
            lineNum="${lineNum%|}"
            output=$(awk -F"$delimiter" -v col="$colNum" -v line="$lineNum" 'NR==line {print $col}' "$selected_file")
            yad --info --window-icon=dialog-information --image=dialog-information \
                --text="Column $colNum at line $lineNum:\n\n$output" --width=350 --height=150
        fi
    fi

    # COUNT İŞLEMLERİ - CSV/TSV
    if [ "$f3" == "number of lines" ]; then
        output=$(awk 'END {print "Total number of lines:", NR}' "$selected_file")
        yad --info --window-icon=dialog-information --image=dialog-information \
            --text="$output" --width=300 --height=120
    
    elif [ "$f3" == "longest line of the file" ]; then
        output=$(awk '{if(length($0) > max) {max=length($0); line=$0; lineno=NR}} END {print "Line number:", lineno, "\nLength:", max, "\nContent:", line}' "$selected_file")
        yad --info --window-icon=dialog-information --image=dialog-information \
            --text="$output" --width=650 --height=200
    fi

    # REPLACEMENT İŞLEMLERİ - CSV/TSV
    if [ "$f4" == "all occurences of a string" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace All Occurrences" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText <<< "$arrayReplace"
            replaceText="${replaceText%|}"
            output=$(sed "s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced: $findText -> $replaceText" --window-icon=gtk-find-and-replace \
                --text="$output" --width=750 --height=500 \
                --button="gtk-save:0" --button="gtk-close:1"
            
            if [ $? -eq 0 ]; then
                savePath=$(yad --file-selection --save --title="Save modified file" \
                    --window-icon=gtk-save \
                    --filename="$selected_file.modified")
                if [ -n "$savePath" ]; then
                    echo "$output" > "$savePath"
                    yad --info --window-icon=dialog-information --image=dialog-information \
                        --text="File saved to: $savePath" --width=300
                fi
            fi
        fi
    
    elif [ "$f4" == "occurences of a string from specific line" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace from Specific Line" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --form --field="Line number" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText lineNum <<< "$arrayReplace"
            lineNum="${lineNum%|}"
            output=$(sed "${lineNum}s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced in line $lineNum" --window-icon=gtk-find-and-replace \
                --text="$output" --width=750 --height=500
        fi
    
    elif [ "$f4" == "occurences of a string from a specific range of line" ]; then
        arrayReplace=$(yad --form --separator='|' --title="Replace in Line Range" \
            --window-icon=gtk-find-and-replace \
            --form --field="Text to find" \
            --form --field="Replace with" \
            --form --field="From line number" \
            --form --field="To line number" \
            --width=350)
        
        if [ -n "$arrayReplace" ]; then
            IFS='|' read -r findText replaceText fromLine toLine <<< "$arrayReplace"
            toLine="${toLine%|}"
            output=$(sed "${fromLine},${toLine}s/$findText/$replaceText/g" "$selected_file")
            yad --text-info --title="Replaced in lines $fromLine-$toLine" --window-icon=gtk-find-and-replace \
                --text="$output" --width=750 --height=500
        fi
    fi

    # DELETE İŞLEMLERİ - CSV/TSV
    if [ "$f5" == "Delete pattern from file" ]; then
        arrayPattern=$(yad --form --separator='|' --title="Delete Pattern" \
            --window-icon=gtk-delete \
            --form --field="Enter pattern to delete" \
            --width=350)
        
        if [ -n "$arrayPattern" ]; then
            pattern="${arrayPattern%|}"
            output=$(sed "/$pattern/d" "$selected_file")
            yad --text-info --title="Lines with pattern '$pattern' deleted" --window-icon=gtk-delete \
                --text="$output" --width=750 --height=500 \
                --button="gtk-save:0" --button="gtk-close:1"
            
            if [ $? -eq 0 ]; then
                savePath=$(yad --file-selection --save --title="Save modified file" \
                    --window-icon=gtk-save \
                    --filename="$selected_file.modified")
                if [ -n "$savePath" ]; then
                    echo "$output" > "$savePath"
                    yad --info --window-icon=dialog-information --image=dialog-information \
                        --text="File saved to: $savePath" --width=300
                fi
            fi
        fi
    
    elif [ "$f5" == "Delete specific line" ]; then
        arrayLineNum=$(yad --form --separator='|' --title="Delete Line" \
            --window-icon=gtk-delete \
            --form --field="Enter line number to delete" \
            --width=350)
        
        if [ -n "$arrayLineNum" ]; then
            lineNum="${arrayLineNum%|}"
            output=$(sed "${lineNum}d" "$selected_file")
            yad --text-info --title="Line $lineNum deleted" --window-icon=gtk-delete \
                --text="$output" --width=750 --height=500
        fi
    fi

else
    yad --error --window-icon=dialog-error --image=dialog-error \
        --text="Invalid file type: $selected_file_type" --width=300
    exit 1
fi

exit 0
