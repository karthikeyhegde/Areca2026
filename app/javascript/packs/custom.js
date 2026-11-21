
function indianFormat(amount) {
	var delimiter = ","; // replace comma if desired
	amount = new String(amount);
	var a = amount.split('.',2);
	var dec = ''
	var k = a[0]
	var istr =  k.split('').reverse().join('');

	if(a[1].length > 0){
      dec = '.'+a[1]
	}
	var ln = a[0].length -1
	i =0;

	 var rn_str = '';
	 while ( i <= ln ){
        if ( i == 3  || ( i > 4 && i%2 == 1)){
           rn_str += ','
        }

        rn_str += istr[i];
        i++;

	 }
	 rs = rn_str.split('').reverse().join('');
	 return rs+dec
   
}