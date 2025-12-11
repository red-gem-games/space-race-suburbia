var m_strUpperCase="ABCDEFGHIJKLMNOPQRSTUVWXYZ";var m_strLowerCase="abcdefghijklmnopqrstuvwxyz";var m_strNumber="0123456789";var m_strCharacters="!@#$%^&*?_~"
function checkPassword(strPassword){var nScore=0;if(strPassword.length<5){nScore+=5}else if(strPassword.length>4&&strPassword.length<8){nScore+=10}else if(strPassword.length>7){nScore+=25}
var nUpperCount=countContain(strPassword,m_strUpperCase);var nLowerCount=countContain(strPassword,m_strLowerCase);var nLowerUpperCount=nUpperCount+nLowerCount;if(nUpperCount==0&&nLowerCount!=0){nScore+=10}else if(nUpperCount!=0&&nLowerCount!=0){nScore+=20}
var nNumberCount=countContain(strPassword,m_strNumber);if(nNumberCount==1){nScore+=10}
if(nNumberCount>=3){nScore+=20}
var nCharacterCount=countContain(strPassword,m_strCharacters);if(nCharacterCount==1){nScore+=10}
if(nCharacterCount>1){nScore+=25}
if(nNumberCount!=0&&nLowerUpperCount!=0){nScore+=2}
if(nNumberCount!=0&&nLowerUpperCount!=0&&nCharacterCount!=0){nScore+=3}
if(nNumberCount!=0&&nUpperCount!=0&&nLowerCount!=0&&nCharacterCount!=0){nScore+=5}
return nScore}
function runPassword(strPassword,strFieldID){var nScore=checkPassword(strPassword);var ctlText=document.getElementById(strFieldID+"_text");if(strPassword.length<6){var strText="Too short";var strColor="#FF00FF";var strColor_light="#f2f2f2";var strColor_border="#dbdbdb";var str_icon="signup_check_short.gif"}else if(nScore>=60){var strText="Very Strong";var strColor="#00BB00";var strColor_light="#f0fee9";var strColor_border="#e1efdb";var str_icon="signup_check_verygood.gif"}else if(nScore>=50){var strText="Strong";var strColor="#00BB00";var strColor_light="#f5ffcf";var strColor_border="#e3e5a3";var str_icon="signup_check_strong.gif"}else if(nScore>=25){var strText="Good";var strColor="#00BB00";var strColor_light="#fff0cf";var strColor_border="#e5d5a3";var str_icon="signup_check_good.gif"}else{var strText="Weak";var strColor="#00BB00";var strColor_light="#ffe2cf";var strColor_border="#e5bda3";var str_icon="signup_check_weak.gif"}
ctlText.innerHTML="<span style='color: "+strColor+"; font-weight:bold'>"+strText+"</span>"}
function countContain(strPassword,strCheck){var nCount=0;for(i=0;i<strPassword.length;i++){if(strCheck.indexOf(strPassword.charAt(i))>-1){nCount++}}
return nCount}