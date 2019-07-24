require 'parslet'

module Soql

  def self.parse(soql)

    parser = Parser.new
    #transformer = Transformer.new

    p tree = parser.parse(soql)
    #puts; p tree; puts
    #out = transformer.apply(tree)

    #out
  end

  class Parser < Parslet::Parser

    def assign()
        #return Object.assign.apply(null, arguments);
    end

    def createLogicalConditionTree(operator, head, tail)
#        result = head
#        for (var i = 0; i < tail.length; i++) {
#          result = {
#            type: 'LogicalCondition',
#            operator: operator,
#            left: result,
#            right: tail[i],
#          };
#        }
#        return result;
#      }
    end
    
    def is_reserved(word)
        #return /^(SELECT|FROM|AS|USING|WHERE|AND|OR|NOT|GROUP|BY|ORDER|LIMIT|OFFSET|FOR|TRUE|FALSE|NULL)$/i.test(word);
      
    end

    def stri(str)        
      key_chars = str.split(//)
      key_chars.
        collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
        reduce(:>>)
    end

    root(:query)

    rule(:spaces) { match('\s').repeat(1) }
    rule(:spaces?) { spaces.maybe }

    rule(:comma) { spaces? >> str(',') >> spaces? }
    rule(:digit) { match('[0-9]') }
    rule(:digits) { digit.repeat(1) }
    rule(:anything) {match('.').repeat(1)}

    rule(:query){
      #spaces? >> 
      #stri(SELECT) >>
      reserved >>
      spaces? >> 
      query_field_list.as(:fields) >>
      spaces? >> 
      from_clause.as(:object) >>
      spaces?
      #>>
      #(spaces? >> where_clause).maybe
    }
    
    rule(:reserved){
      exp("select")
    }

    rule(:query_field_list){
      query_field_list_item.as(:fields) >> comma >> query_field_list | query_field_list_item.as(:fields)
    }

    rule(:query_field_list_item){
      sub_query | query_field
    }

    rule(:query_field){
      #field_expr >> spaces? >> identifier.as(:alias) | field_expr
      field_expr
    }

    rule(:field_expr){
      function_call | field_reference
    }

    rule(:function_call){
      identifier.as(:func) >> spaces? >> str(LPAREN) >> spaces? >> function_arg.as(:args) >> spaces? >> str(RPAREN)
    }

    rule(:function_arg){
      field_reference.repeat(1)
    }

    rule(:field_reference){
      field_path.as(:path)
    }

    rule(:field_path){
      identifier.as(:field) >> str(DOT) >> field_path | identifier.as(:field)
    }

    rule(:from_clause){
      stri(FROM) >> spaces >> object_reference.as(:object) #>> (comma >> alias_object_list.as(:alias_objects)).maybe
    }
 
    rule(:object_reference){
      identifier.as(:name) #>> (spaces? >> (stri(AS) >> spaces?).maybe >> identifier).maybe.as(:alias)
    }

    rule(:alias_object_list){
      alias_object_reference >> comma >> alias_object_list | alias_object_reference
    }

    rule(:alias_object_reference){
      field_path.as(:path) >> (spaces? (stri(AS) >> spaces?).maybe >> identifier.as(:alias)).maybe
    }

    rule(:where_clause){
      stri(WHERE) >> spaces >> anything.as(:conditions)
    }
    
    rule(:sub_query){
      str(LPAREN) >>
      spaces? >>
      stri(SELECT) >>
      spaces? >>
      sub_query_fieldList.as(:fields)
      spaces? >>
      from_clause.as(:object) >>
      (spaces? >> where_clause).maybe
    }

    rule(:sub_query_fieldList){
      sub_query_field_list_item >> comma >> sub_query_fieldList | sub_query_field_list_item.as(:field)
    }

    rule(:sub_query_field_list_item){
      field_expr
    }

    rule(:identifier){
      !str("id") && match('\w').repeat(1)
    }
  
=begin
    ScopeClause =
      USING spaces? SCOPE spaces? scope:FilterScope {
        return scope;
      }

    FilterScope =
      "Delegated" { return 'Delegated'; }
    / "Everything" { return 'Everything'; }
    / "Mine" { return 'Mine'; }
    / "My_Territory" { return 'My_My_Territory'; }
    / "My_Team_Territory" { return 'My_Team_Territory'; }
    / "Team" { return 'Team'; }

    WhereClause =
      WHERE spaces? condition: Condition {
        return condition
      }

    Condition =
      OrCondition

    OrCondition =
      head:AndCondition tail:(spaces? OR spaces? condition:AndCondition { return condition; })* {
        return createLogicalConditionTree('OR', head, tail);
      }

    AndCondition =
      head:NotCondition tail:(spaces? AND spaces? condition:NotCondition { return condition; })* {
        return createLogicalConditionTree('AND', head, tail);
      }

    NotCondition =
      NOT spaces? condition:ParenCondition {
        return {
          type: 'NegateCondition',
          operator: 'NOT',
          condition: condition,
        };
      }
    / ParenCondition

    ParenCondition =
      LPAREN _ condition:Condition _ RPAREN {
        return assign({}, condition, { parentheses: true });
      }
    / ComparisonCondition

    ComparisonCondition =
      field:FieldExpr
      operator:(
          _ o:SpecialCharComparisonOperator _ { return o; }
        / spaces? o:ComparisonOperator spaces? { return o; }
      )
      value:ComparisonValue {
        return {
          type: 'ComparisonCondition',
          field: field,
          operator: operator,
          value: value,
        };
      }

    SpecialCharComparisonOperator =
      "=" / "!=" / "<=" / ">=" / "<" / ">"

    ComparisonOperator =
      "LIKE" { return 'LIKE'; }
    / "N" { return 'IN'; }
    / "NOT" spaces? "N" { return 'NOT IN'; }
    / "NCLUDES" { return 'INCLUDES'; }
    / "EXCLUDES" { return 'EXCLUDES'; }

    ComparisonValue =
      SubQuery
    / ListLiteral
    / Literal
    / BindVariable

    GroupByClause =
      GROUP spaces? BY spaces? ROLLUP _ LPAREN _ fields:GroupItemList _ RPAREN {
        return {
          type: 'RollupGrouping',
          fields: fields
        };
      }
    / GROUP spaces? BY spaces? CUBE _ LPAREN _ fields:GroupItemList _ RPAREN {
        return {
          type: 'CubeGrouping',
          fields: fields
        };
      }
    / GROUP spaces? BY spaces? fields:GroupItemList {
        return {
          type: 'Grouping',
          fields: fields,
        };
      }

    GroupItemList =
      head:GroupItem _ COMMA _ tail:GroupItemList {
        return [head].concat(tail);
      }
    / group:GroupItem {
        return [group];
      }

    GroupItem =
      FieldExpr

    OrderByClause =
      ORDER spaces? BY spaces? sort:SortItemList {
        return sort;
      }

    SortItemList =
      head:SortItem _ COMMA _ tail:SortItemList {
        return [head].concat(tail);
      }
    / sort:SortItem {
        return [sort];
      }

    SortItem =
      field:FieldExpr
      direction:(spaces? SortDir)?
      nullOrder:(spaces? NullOrder)? {
        return assign(
          { field: field },
          direction ? { direction: direction[1] } : {},
          nullOrder ? { nullOrder: nullOrder[1] } : {}
        );
      }

    SortDir =
      ASC { return 'ASC'; }
    / DESC { return 'DESC'; }

    NullOrder =
      NULLS spaces? FIRST { return 'FIRST'; }
    / NULLS spaces? LAST { return 'LAST'; }

    LimitClause =
      LIMIT spaces? value:LimitValue {
        return value;
      }

    LimitValue =
      NumberLiteral
    / BindVariable

    OffsetClause =
      OFFSET spaces? value:OffsetValue {
        return value;
      }

    OffsetValue =
      NumberLiteral
    / BindVariable

    SelectForClause =
      FOR spaces? VIEW { return 'VIEW'; }
    / FOR spaces? REFERENCE { return 'REFERENCE'; }

    SubQuery =
      LPAREN
      _ SELECT
      spaces? fields:SubQueryFieldList
      spaces? object:FromClause
      condition:(spaces? WhereClause)?
      sort:(spaces? OrderByClause)?
      limit:(spaces? LimitClause)?
      _ RPAREN {
        return assign(
          {
            type: 'Query',
            fields: fields,
            object: object,
          },
          condition ? { condition: condition[1] } : {},
          sort ? { sort: sort[1] } : {},
          limit ? { limit: limit[1] } : {}
        );
      }

    SubQueryFieldList =
      head:SubQueryFieldListItem _ COMMA _ tail:SubQueryFieldList {
        return [head].concat(tail);
      }
    / field:SubQueryFieldListItem {
        return [field]
      }

    SubQueryFieldListItem = FieldExpr

    Identifier =
      id:([a-zA-Z][0-9a-zA-Z_]* { return text() }) & { return !isReserved(id) } { return id; }

    # 'Group' and 'Order' are valid sobjects to query from,
    # as well as are part of the reserved keywords 'GROUP BY' and 'ORDER BY',
    # so we need this special identifier pattern for FromClause
    ObjectIdentifier =
      "GROUP" { return text() }
    / "ORDER" { return text() }
    / Identifier

    BindVariable =
      COLON identifier:Identifier {
        return {
          type: 'BindVariable',
          identifier: identifier,
        };
      }

    ListLiteral =
      LPAREN _ values:LiteralList _ RPAREN {
        return {
          type: 'list',
          values: values,
        };
      }

    LiteralList =
      head:Literal _ COMMA _ tail:LiteralList {
        return [head].concat(tail);
      }
    / Literal

    Literal =
      StringLiteral
    / ISODateLiteral
    / DateLiteral
    / NumberLiteral
    / BooleanLiteral
    / NullLiteral

    NumberLiteral =
      n:Number {
        return {
          type: 'number',
          value: n
        }
      }

    Number =
      int_:Int frac:Frac         { return parseFloat(int_ + frac); }
    / int_:Int                   { return parseFloat(int_); }

    Int
      = digit19:Digit19 digits:Digits { return digit19 + digits; }
      / digit:Digit
      / op:[+-] digits:Digits { return op + digit19 + digits; }
      / op:[+-] digit:Digit { return op + digit; }

    Frac
      = "." digits:Digits { return "." + digits; }

    Digits
      = digits:Digit+ { return digits.join(""); }

    Integer2
      = $(Digit Digit)

    Integer4
      = $(Digit Digit Digit Digit)

    Digit   = [0-9]
    Digit19 = [1-9]

    HexDigit
      = [0-9a-fA-F]

    StringLiteral =
      QUOTE ca:(SingleChar*) QUOTE {
        return {
          type: 'string',
          value: ca.join('')
        };
      }


    SingleChar =
      [^'\\\0-\x1F\x7f]
    / EscapeChar

    EscapeChar =
      "\\'"  { return "'";  }
    / '\\"'  { return '"';  }
    / "\\\\" { return "\\"; }
    / "\\/"  { return "/";  }
    / "\\b"  { return "\b"; }
    / "\\f"  { return "\f"; }
    / "\\n"  { return "\n"; }
    / "\\r"  { return "\r"; }
    / "\\t"  { return "\t"; }
    / "\\u" h1:HexDigit h2:HexDigit h3:HexDigit h4:HexDigit {
      return String.fromCharCode(parseInt("0x" + h1 + h2 + h3 + h4));
    }

    ISODate
     = Integer4 "-" Integer2 "-" Integer2

    ISOTZ
        = "Z"
        / $(("+" / "-") Integer2 ":" Integer2 )
        / $(("+" / "-") Integer4 )

    DateFormatLiteral =
      Integer4 "-" Integer2 "-" Integer2 {
        return {
          type: 'date',
          value: text()
        };
      }

    ISOTime
        = $(Integer2 ":" Integer2 ":" Integer2)

    ISODateLiteral
        = d:ISODate t:$("T" ISOTime)? z:$ISOTZ? {
            return {
              type: t || z ? 'datetime' : 'date',
              value: text()
            }
        }

    DateLiteral =
      d:TODAY {
        return {
          type: 'dateLiteral',
          value: text()
        }
      }
    / d:YESTERDAY {
        return {
          type: 'dateLiteral',
          value: text()
        }
    }
    / d:TOMORROW {
        return {
          type: 'dateLiteral',
          value: text()
        }
    }
    / d:LAST_WEEK {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_WEEK {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_WEEK {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_MONTH {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_MONTH {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_MONTH {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_90_DAYS {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_90_DAYS {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_FISCAL_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_FISCAL_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_FISCAL_QUARTER {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:THIS_FISCAL_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_FISCAL_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:NEXT_FISCAL_YEAR {
      return {
        type: 'dateLiteral',
        value: text()
      }
    }
    / d:LAST_N_DAYS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_DAYS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_WEEKS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_WEEKS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_MONTHS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_MONTHS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_QUARTERS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_QUARTERS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_YEARS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_YEARS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_FISCAL_QUARTERS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_FISCAL_QUARTERS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:NEXT_N_FISCAL_YEARS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }
    / d:LAST_N_FISCAL_YEARS c:_":"_ n:$(Digit+) {
      return {
        type: 'dateLiteral',
        value: d,
        argument: parseInt(n)
      }
    }

    BooleanLiteral =
      TRUE {
        return {
          type: 'boolean',
          value: true
        };
      }
    / FALSE {
      return {
        type: 'boolean',
        value: false
      };
    }

    NullLiteral =
      NULL {
        return {
          type: 'null',
          value: null
        };
      }
=end
    COMMA  = ","
    DOT    = "."
    LPAREN = "("
    RPAREN = ")"
    QUOTE  = "'"
    COLON  = ":"

    # Keywords

    SELECT   = "SELECT"
    FROM     = "FROM"
    AS       = "AS"
    USING    = "USING"
    SCOPE    = "SCOPE"
    WHERE    = "WHERE"
    OR       = "OR"
    AND      = "AND"
    NOT      = "NOT"
    GROUP    = "GROUP"
    BY       = "BY"
    ROLLUP   = "ROLLUP"
    CUBE     = "CUBE"
    ORDER    = "ORDER"
    ASC      = "ASC"
    DESC     = "DESC"
    NULLS    = "NULLS"
    FIRST    = "FIRST"
    LAST     = "LAST"
    LIMIT    = "LIMIT"
    OFFSET   = "OFFSET"
    FOR      = "FOR"
    VIEW     = "VIEW"
    REFERENCE = "REFERENCE"
    TRUE     = "TRUE"
    FALSE    = "FALSE"
    NULL     = "NULL"

    # Date Literals

    YESTERDAY = "YESTERDAY"
    TODAY = "TODAY"
    TOMORROW = "TOMORROW"
    LAST_WEEK = "LAST_WEEK"
    THIS_WEEK = "THIS_WEEK"
    NEXT_WEEK = "NEXT_WEEK"
    LAST_MONTH = "LAST_MONTH"
    THIS_MONTH = "THIS_MONTH"
    NEXT_MONTH = "NEXT_MONTH"
    LAST_90_DAYS = "LAST_90_DAYS"
    NEXT_90_DAYS = "NEXT_90_DAYS"
    THIS_QUARTER = "THIS_QUARTER"
    LAST_QUARTER = "LAST_QUARTER"
    NEXT_QUARTER = "NEXT_QUARTER"
    THIS_YEAR = "THIS_YEAR"
    LAST_YEAR = "LAST_YEAR"
    NEXT_YEAR = "NEXT_YEAR"
    THIS_FISCAL_QUARTER = "THIS_FISCAL_QUARTER"
    LAST_FISCAL_QUARTER = "LAST_FISCAL_QUARTER"
    NEXT_FISCAL_QUARTER = "NEXT_FISCAL_QUARTER"
    THIS_FISCAL_YEAR = "THIS_FISCAL_YEAR"
    LAST_FISCAL_YEAR = "LAST_FISCAL_YEAR"
    NEXT_FISCAL_YEAR = "NEXT_FISCAL_YEAR"
    LAST_N_DAYS = "LAST_N_DAYS"
    NEXT_N_DAYS = "NEXT_N_DAYS"
    NEXT_N_WEEKS = "NEXT_N_WEEKS"
    LAST_N_WEEKS = "LAST_N_WEEKS"
    NEXT_N_MONTHS = "NEXT_N_MONTHS"
    LAST_N_MONTHS = "LAST_N_MONTHS"
    NEXT_N_QUARTERS = "NEXT_N_QUARTERS"
    LAST_N_QUARTERS = "LAST_N_QUARTERS"
    NEXT_N_YEARS = "NEXT_N_YEARS"
    LAST_N_YEARS = "LAST_N_YEARS"
    NEXT_N_FISCAL_QUARTERS = "NEXT_N_FISCAL_QUARTERS"
    LAST_N_FISCAL_QUARTERS = "LAST_N_FISCAL_QUARTERS"
    NEXT_N_FISCAL_YEARS = "NEXT_N_FISCAL_YEARS"
    LAST_N_FISCAL_YEARS = "LAST_N_FISCAL_YEARS"
  end
end
