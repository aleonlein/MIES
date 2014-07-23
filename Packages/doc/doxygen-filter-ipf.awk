# Proof of concept implementation for using doxygen to document Igor Pro procedures
# This awk script serves as input filter for Igor procedures and produces a C-ish version of the declarations
# Tested with Igor Pro 6.3(beta) and doxygen 1.8.1.1
#
# Thomas Braun: 6/2014
# Version: 0.2

# Supported Features:
# -Functions
# -Macros
# -File constants

# TODO
# - handle optional arguments properly
# - don't delete the function/macro subType

BEGIN{
  # allows to bail out for code found outside of functions/macros
  DO_WARN=0
  IGNORECASE=1
  output=""
  warning=""
}

# Remove whitespace at beginning and end of string
function trim(str)
{
  gsub(/^[[:space:]]+/,"",str)
  gsub(/[[:space:]]+$/,"",str)
  return str
}

# Split an already trimmed line into words
# Returns the number of words
function splitIntoWords(str, a, numEntries)
{
  return split(str,a,/[[:space:],&*]+/)
}

# Split params into words and prefix each with "__Param__$i"
# where $i is increased for every parameter
# Returns the concatenation of all prefixed parameters
function handleParameter(params, a, i, str)
{
  numParams = splitIntoWords(params, a)
  str=""
  for(i=1; i <= numParams; i++)
  {
    str = str "__Param__" i " " a[i]
    if(i < numParams)
     str = str ", "
  }
  return str
}

{
  # split current line into code and comment
  if(match($0,/\/\/.*/))
  {
    code=substr($0,0,RSTART-1)
    comment=substr($0,RSTART,RLENGTH)
  }
  else
  {
    code=$0
    comment=""
  }
  # remove whitespace from front and back
  code=trim(code)

  # begin of macro definition
  if(!insideFunction && !insideMacro && ( match(code,/^Window/)|| match(code,/^Proc/) || match(code,/^Macro/) ) )
  {
    insideMacro=1
    gsub(/^Window/,"void",code)
    gsub(/^Macro/,"void",code)
    gsub(/^Proc/,"void",code)

    # add opening bracket, this also throws away any function subType
    gsub(/\).*/,"){",code)
  }
  # end of macro definition
  else if(!insideFunction && insideMacro && ( match(code,/^EndMacro$/) || match(code,/^End$/) ) )
  {
    insideMacro=0
    code = "}"
  }
  # begin of function declaration
  else if(!insideFunction && ( match(code,/[[:space:]]function[\/[[:space:]]/) || match(code,/^function[\/[[:space:]]/) ) )
  {
    insideFunction=1
    # remove whitespace between function and return type flag
    gsub(/function[[:space:]]*\//,"function\/",code)

    # different return types
    gsub(/function /,"variable ",code)
    gsub(/function\/df/,"dfr",code)
    gsub(/function\/wave/,"wave",code)
    gsub(/function\/c/,"complex",code)
    gsub(/function\/s/,"string",code)
    gsub(/function\/t/,"string",code) # deprecated definition of string return type
    gsub(/function\/d/,"variable",code)

    # add opening bracket, this also throws away any function subType
    gsub(/\).*/,"){",code)

    # do we have function parameters
    if(match(code,/\(.*[a-z]+.*\)/))
    {
      paramStr = substr(code,RSTART+1,RLENGTH-2)

      # convert optional parameters to normal parameters
      gsub(/[\[\]]/,"",paramStr)

      paramStrWithTypes = handleParameter(paramStr, params)
      paramsToHandle = numParams
      # print "paramStr __ " paramStr
      # print "paramStrWithTypes __ " paramStrWithTypes
      # print "paramsToHandle __ " paramsToHandle

      code = substr(code,0,RSTART) "" paramStrWithTypes "" substr(code,RSTART+RLENGTH-1)
    }
  }
  else if(insideFunction && paramsToHandle > 0)
  {
   numEntries = splitIntoWords(code,entries)

   # printf("Found %d words in line \"%s\"\n",numEntries,code)
    for(i=2; i <= numEntries; i++)
      for(j=1; j <= numParams; j++)
      {
        variableName = entries[i]
        if( entries[i] == params[j] )
        {
          paramsToHandle--
          # now replace __Param__$i with the real parameter type
          if(entries[1] == "struct")
            paramType = entries[2]
          else
            paramType = tolower(entries[1])

          # add asterisk for call-by-reference parameters
          if(match(code,/\&/))
            paramType = paramType "*"

          output = gensub("__Param__" j " ",paramType " ","g",output)
          # printf("Found parameter type %s at index %d\n",paramType,j)
        }
      }
  }
  # end of function declaration
  else if(insideFunction && match(code,/^end$/))
  {
    insideFunction=0
    code = "}"
  }

  # structure declaration
  if(!insideFunction && !insideMacro && ( match(code,/[[:space:]]structure[[:space:]]/) || match(code,/^structure[[:space:]]/) )  )
  {
    insideStructure=1
    gsub(/structure/,"struct",code)
    code = code "{"
  }

  if(insideStructure && match(code,/EndStructure/))
  {
    insideStructure=0
    code = "}"
  }

  # global constants
  gsub("strconstant","const string",code)
  gsub("constant","const variable",code)
  # prevent that doxygen sees elseif as a function call
  gsub("elseif","else if",code)

  # code outside of function/macro definitions is "translated" into statements
  if(!insideFunction && !insideMacro && code != "" && substr(code,0,1) != "#")
  {
    if(code != "}" && !insideStructure && DO_WARN)
      warning = warning "\n" "warning " NR ": outside code \"" code "\""

    code = code ";"
  }

  output = output "\n" code "" comment
}

END{
  print output

  if(DO_WARN)
    print warning
}