function indianFormat(amount) {
	var delimiter = ","; // replace comma if desired
	amount = new String(amount);
	var a = amount.split('.',2);
	var dec = ''
	var k = a[0]
	var istr =  k.split('').reverse().join('');

	if (a[1] && a[1].length > 0){
      dec = '.'+a[1]
      if (a[1].length < 2){
        dec += '0' 
      }     
	}
	var ln = a[0].length -1
	var i = 0;
	var rn_str = '';
	while ( i <= ln ){
        if ( i == 3  || ( i > 4 && i%2 == 1)){
           rn_str += ','
        }
        rn_str += istr[i];
        i++;
	}
	var rs = rn_str.split('').reverse().join('');
	return rs+dec
   
}

function PrintElem(elem)
{
    var mywindow = window.open('', 'PRINT', 'height=400,width=600');

    mywindow.document.write('<html><head><title>' + document.title  + '</title>');
    mywindow.document.write('</head><body >');
    mywindow.document.write('<h1>' + document.title  + '</h1>');
    mywindow.document.write(document.getElementById('balance_div').outerHTML)
    mywindow.document.write(document.getElementById('user_balance_table').innerHTML);
    mywindow.document.write('</body></html>');

    mywindow.document.close(); // necessary for IE >= 10
    mywindow.focus(); // necessary for IE >= 10*/

    mywindow.print();
    mywindow.close();

    return true;
}


window.indianFormat = indianFormat;
