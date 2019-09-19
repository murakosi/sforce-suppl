require 'parslet'

module Soql
  module SoqlParser

    def self.parse(soql)

      parser = Parser.new
      transformer = Transformer.new

      tree = parser.parse(soql.upcase)

      transformer.apply(tree)

    end

    class Parser < Parslet::Parser

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
      rule(:left_paren){ spaces? >> str(LPAREN) >> spaces? }
      rule(:right_paren){ spaces? >> str(RPAREN) >> spaces? }
      rule(:anything) {match('.').repeat(1)}

      rule(:query){
        spaces? >> 
        str(SELECT) >>
        spaces? >> 
        query_field_list.as(:fields) >>
        spaces? >> 
        from_clause.as(:objects) >>      
        spaces? >>
        anything.maybe
      }
      
      rule(:reserved){
        reserved_word >> match('[0-9a-zA-Z_]').absent?
      }

      rule(:reserved_word){
        str(SELECT) | str(FROM) | str(AS) | str(USING) | 
        str(WHERE) | str(AND) | str(OR) | str(NOT) | str(GROUP) | 
        str(BY) | str(ORDER) | str(LIMIT) | str(OFFSET) | str(FOR) | 
        str(TRUE) | str(FALSE) | str(NULL)
      }

      rule(:query_field_list){
        query_field_list_item >> comma >> query_field_list | query_field_list_item
      }

      rule(:query_field_list_item){
        query_fields.repeat(1)
      }

      rule(:query_fields){
        sub_query | query_field
      }

      rule(:query_field){
        field_expr.as(:name) >> spaces >> identifier.as(:alias) | field_expr.as(:name)
      }

      rule(:field_expr){
        function_call.as(:function) | field_reference
      }
      
      rule(:function_call){
        count_all.as(:count_ast) | identifier.as(:function_name) >> left_paren >> field_reference >> right_paren >> function_alias.maybe
      }
      
      rule(:count_all){
        str(COUNT) >> left_paren >> spaces? >> right_paren
      }
      
      rule(:function_alias){
        identifier.as(:function_alias)
      }

      rule(:field_reference){
         identifier >> str(DOT) >> field_reference | identifier
      }

      rule(:from_clause){
        str(FROM) >> spaces >> object_item_list
      }
   
      rule(:object_item_list){
        object_item_list_item >> comma >> object_item_list | object_item_list_item
      }

      rule(:object_item_list_item){
        object_reference.repeat(1)
      }

      rule(:object_reference){
        field_reference.as(:object_name) >> (as | spaces) >> identifier.as(:object_alias) | field_reference.as(:object_name)
      }

      rule(:as){
        spaces? >> str(AS) >> spaces?
      }

      rule(:where_clause){
        match("[0-9a-zA-Z_\'\s'='!'>'<]").repeat
      }

      rule(:sub_query){
        spaces? >>
        str(LPAREN) >>
        spaces? >>
        str(SELECT) >>
        spaces? >>
        sub_query_fieldList >>
        spaces? >>
        sub_from_clause.as(:sub_query) >>
        spaces? >>
        where_clause.maybe >>
        str(RPAREN)
      }

      rule(:sub_query_fieldList){
        sub_query_field_list_item >> comma >> sub_query_fieldList | sub_query_field_list_item
      }

      rule(:sub_query_field_list_item){
        field_expr
      }

      rule(:sub_from_clause){
        str(FROM) >> spaces >> sub_object_reference
      }
   
      rule(:sub_object_reference){
        field_reference.as(:object_name) >> as >> identifier.as(:object_alias) | field_reference.as(:object_name)
      }

      rule(:identifier){
        reserved.absent? >> match('[0-9a-zA-Z_]').repeat(1)
      }

      COMMA  = ","
      DOT    = "."
      LPAREN = "("
      RPAREN = ")"

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
      COUNT    = "COUNT"

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

    class Transformer < Parslet::Transform

      rule(:object_name => simple(:o)){
        {:object_name => o.to_s}
      }

      rule(:object_name => simple(:o), :object_alias => simple(:als)) {
        {:object_name => o.to_s, :object_alias => als.to_s }
      }

      rule(:name => simple(:f)){
        {:name => f.to_s}
      }

      rule(:name => simple(:f), :alias => simple(:als)){
        {:name => f.to_s, :alias => als.to_s}
      }

      rule(:reference => simple(:ref)){
        {:reference => ref.to_s}
      }

    end
  end
end
