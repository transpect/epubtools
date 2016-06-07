#!/bin/bash

function usage {
    echo ""
    echo "escape-for-amzn-region-magnification.sh"
    echo ""
    echo "This script changes single quotes with double quotes and vice versa"
    echo "for Amazon Kindle Region Magnification"
    echo ""
    echo "Prerequisites: Bash shell and sed command"
    echo ""
    echo "Usage: ./epubconvertescape-for-amzn-region-magnification.sh <file.html>"
    echo ""
    1>&2; exit 1;
}


if [ -z $1 ]; then
    usage
fi

FILE=$1


cat $FILE | sed -u 's/&#34;/\"/g' | sed -u "s/=\"{/='{/g" | sed -u "s/}\">/}'>/g" > "$FILE";
