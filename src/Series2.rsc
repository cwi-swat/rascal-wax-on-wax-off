module Series2

import ParseTree;
import IO;
import ValueIO;

// I'm lazy, I reuse Layout and Id (identifier) syntax.
extend lang::std::Layout;

/*
 * Syntax definition
 * - define a grammar for JSON (https://json.org/)
 */
 
start syntax JSON
  = Object;
  
syntax Object
  = "{" {Prop ","}* "}";
  
syntax Prop
  = String ":" Value
  ;
  
syntax Value
  = String
  | Number
  | Array
  | Object
  | Boolean
  | Null
  ;

syntax Null
  = "null";
  
syntax Boolean
  = "true" | "false"; 
  
syntax Array
  = "[" {Value ","}* "]";
  
lexical String
  = [\"] ![\"]* [\"]; // slightly simplified
  
lexical Number
  = [1-9][0-9]* ("." [0-9]*)?
  | [0] ("." [0-9]*)?  
  ;
  
  

// import the module in the console
start[JSON] example() 
  = parse(#start[JSON], 
          "{
          '  \"age\": 42, 
          '  \"name\": \"Joe\",
          '  \"address\": {
          '     \"street\": \"Wallstreet\",
          '     \"number\": 102
          '  }
          '}");    
  


// use visit/deep match to find all property names
// - use concrete pattern matching
// - use "<x>" to convert a String x to str
set[str] propNames(start[JSON] json) {
  set[str] names = {};
  
  visit (json) {
    case (Prop)`<String x>: <Value _>`:
      names += "<x>"[1..-1];
  }
  
  return names;
}


// define a recursive transformation mapping JSON to map[str,value] 
// - use the module ValueIO to parse strings into Rascal values
// - define a data type for representing null;

map[str, value] json2map(start[JSON] json) = json2map(json.top);

data Null = null();

map[str, value] json2map((JSON)`<Object obj>`)  = m
  when map[str, value] m := json2value((Value)`<Object obj>`);

value json2value(Value v) {
  switch (v) {
    case (Value)`null`: 
      return null();
    case (Value)`<String s>`: 
      return readTextValueString(#str, "<s>");
    case (Value)`<Number n>`:
      return readTextValueString(#num, "<n>");
    case (Value)`<Boolean b>`:
      return readTextValueString(#bool, "<b>");
    case (Value)`[<{Value ","}* xs>]`:
      return [ json2value(x) | Value x <- xs ];
    case (Value)`{<{Prop ","}* xs>}`:
      return ( readTextValueString(#str, "<s>"): json2value(x) 
                | (Prop)`<String s>: <Value x>` <- xs );
    default:
      throw "Bad value: <v>";
  }
}

test bool example2map() = json2map(example()) == (
  "age": 42,
  "name": "Joe",
  "address" : (
     "street" : "Wallstreet",
     "number" : 102
  )
);

 
  
/*
 * Optionally: do this tutorial to get more familiarized with concrete syntax
 * by extending Javascript with new language features:
 *   https://github.com/cwi-swat/hack-your-javascript
 */  
  
