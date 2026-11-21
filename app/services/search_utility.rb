	class SearchUtility


		def self.searchable_columns
		   [  ['contact_id', 'id'],
		      ['item_id', 'id'],
		      ['on_date', 'date'],
		      ['vehicle_number', 'text'],
		      ['note','text']
		   ]
	    end

	    def self.stk_search_sql(params, searchcolumns = SearchUtility.searchable_columns)
	    	sql_str = []

	    	searchcolumns.each{|col|
	    	param_col = params[col[0]]
	          next if params[col[0]].blank?
	          case  col[1]
	            when 'id'
		             if param_col.class == 'String' && param_col.include?(',')
		             	sql_str << ' '+col[0]+'  in ('+param_col+')'
		             else
		               sql_str <<  	" "+col[0]+" = "+param_col.to_s+" " 
		             end 
	           when 'text'
	             sql_str <<  " "+col[0]+" LIKE '%"+param_col+"%' " 

	           when 'date'
	           	   date_hash = param_col
	              if  !param_col['from_date'].blank? && !param_col['to_date'].blank?
	              	 sql_str << " "+col[0]+" >= '"+param_col['from_date'] + "'' and "+col[0]+" <= '"+param_col['to_date']+"' "
	              else	
	              	 sql_str << " "+col[0]+" >= '"+param_col['from_date']+"' " if !param_col['from_date'].blank?
	              	 sql_str << " "+col[0]+" <= '"+param_col['to_date']+"' "   if !param_col['to_date'].blank?
	              end
	           end   	
	    	}
	    	return sql_str.join( " and ")

	    end 	

	end