#!/bin/bash
function usage {
    echo ""
    echo "pyftsubset.sh"
    echo ""
    echo "usage: pyftsubset.sh -g [glyphs] -o [outfile] font-file"
    echo ""
    exit 1
}

while getopts ":g:o" opt; do
    case "${opt}" in
	g)
	    GLYPHS=${OPTARG}
	    ;;
	o)
	   OUTFILE=${OPTARG}
	    ;;
	\?)
	    echo "invalid option -$OPTARG" >&2
	    ;;
	:)
	    echo "option $OPTARG requires an argument" >&2
	    ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $1 ]]; then
  echo ""
  echo "no glyphs used for this font $GLYPHS"
  exit 1
fi

FILE=$(readlink -f $1)

if [[ ! -f $FILE ]]; then
    NEWPATH="/"$1
    FILE=$(readlink -f $NEWPATH)
    if [[ ! -f $FILE ]]; then
     	echo ""
     	echo "font file not found $1"
     	exit 1
    fi
fi

if [[ -z $OUTFILE ]]; then
    OUTFILE=$FILE.subset
fi

echo ""
echo "~~~~~ start font subsetting ~~~~~"
echo "FILE: $FILE"
echo "GLYPHS (unicode): $GLYPHS"
echo "OUTPUT: $OUTFILE"
echo "~~~~~ font subsetting finished ~~~~~"

pyftsubset $FILE --unicodes=$GLYPHS --output-file=$OUTFILE --ignore-missing-glyphs
