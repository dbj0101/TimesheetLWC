import { LightningElement, api } from 'lwc';
import setTimeValue from '@salesforce/apex/TimeSheetComponentController.setTimeValue';

export default class TimeProjectInput extends LightningElement {
    @api readOnly=false;
    @api itemId;
    @api itemName;
    @api itemValue;
    @api itemIndex;

    handleOnChange(event) {
        //console.log('timeProjectInput.handleOnChange - '+this.itemName+': '+event.target.value+' ## Previous Value:'+this.itemValue); 
        //this.itemValue = event.target.value;
        
    }

    handleKeyPress(event) {
        //https://stackoverflow.com/questions/18608954/how-to-prevent-user-from-entering-special-characters-in-text-box-when-length-is/18609233
        //Only allow numbers, :, and .
        console.log('handleKeyPress event.key: '+event.key);
        const regex = new RegExp('^[0-9:\.]*$');
        console.log('test regex: '+regex.test(event.key));
        if(!(regex.test(event.key))) {
            console.log('prevent DEFAULT');
            event.preventDefault();
        }
    }

    handleOnBlur(event) {
        console.log('handleOnBlur '+this.itemName+': '+'event.key: '+event.target.value);
        let tempVal=event.target.value;
        
        //https://melvingeorge.me/blog/remove-all-non-alphanumeric-characters-string-javascript
        //removed all characters not 0123456789:.
        tempVal = tempVal.replace(/[^0-9:\.]/g, '');
        //console.log('replaced tempVal:'+tempVal);
        //start some hardcore string verification
        //only want to allow formats ##:##
        //so convert ##.## to ##:## or ## to ##:##
        //and many other weird inputs that could come up
        if(tempVal.length>0) {
            if(tempVal.indexOf(':')>-1) {
                tempVal=tempVal.replaceAll('.','');
                //console.log(tempVal.split(':'));
                let tempArray=tempVal.split(':');
                if(tempArray.length<2) { tempArray.push(['0']); }
                if(tempArray[0]=='') { tempArray[0]='0'; }
                if(tempArray[1]=='') { tempArray[1]='0'; }
                if(tempArray.length>2) {
                    let ta = [tempArray[0], tempArray[1]];
                    let i=2;
                    for(i=2; i<tempArray.length; i++) {
                        ta[1]=ta[1]+tempArray[i];
                    }
                    tempArray=ta;
                }
                //console.log(tempArray);
                //let hours=Math.floor(Math.floor(tempArray[1]) / 60);
                //hours=hours+Math.floor(tempArray[0]);
                //let minutes=Math.floor(Math.floor(tempArray[1] % 60));
                //console.log('hours:'+hours+' ## minutes:'+minutes);
                
                let hoursStr=(Math.floor(Math.floor(tempArray[1]) / 60)+Math.floor(tempArray[0])).toString();
                let minutesStr=('0'+Math.floor(Math.floor(tempArray[1] % 60))).slice(-2);
                //console.log('hours:'+hoursStr+' ## minutes:'+minutesStr);
                //console.log(hoursStr+':'+minutesStr);
                tempVal = hoursStr+':'+minutesStr;
            }//if(tempVal.indexOf(':')>-1)
            else {
                tempVal=tempVal.replaceAll(':','');
                let tempArray=tempVal.split('.');
                if(tempArray.length<2) { tempArray.push(['0']); }
                if(tempArray[0]=='') { tempArray[0]='0'; }
                if(tempArray[1]=='') { tempArray[1]='0'; }
                if(tempArray.length>2) {
                    let ta = [tempArray[0], tempArray[1]];
                    let i=2;
                    for(i=2; i<tempArray.length; i++) {
                        ta[1]=ta[1]+tempArray[i];
                    }
                    tempArray=ta;
                }
                let hours=Math.floor(tempArray[0]);
                //console.log(parseFloat('0.'+tempArray[1]));
                let minutes=Math.round(parseFloat('0.'+tempArray[1])*60);
                if(minutes>=60) { hours=hours+1; minutes=0; }//JIC something like 5.999999 is entered and rounds-up to 5.60
                //console.log('hours:'+hours+' ## minutes:'+minutes);
                
                let hoursStr=hours.toString();
                let minutesStr=('0'+(minutes.toString())).slice(-2);
                //console.log('hours:'+hoursStr+' ## minutes:'+minutesStr);
                //console.log(hoursStr+':'+minutesStr);
                tempVal = hoursStr+':'+minutesStr;
            } //else - if(tempVal.indexOf(':')>-1)
        } //if(tempVal.length>0)
        else {
            tempVal='0:00';
        }
        event.target.value = tempVal;
        console.log('compare this.itemValue:'+this.itemValue+' ## event.target.value:'+event.target.value);
        if(this.itemValue != event.target.value) {
            this.itemValue = event.target.value;

            //updates Salesforce Timesheet_Item__c object
            setTimeValue({timeSheetItemId: this.itemId, hours: this.itemValue}).then(result =>{
                console.log('timeProjectInput.setTimeValue SUCCESS result>>');
                console.log(JSON.stringify(result));
            }).catch(error => {
                console.error('timeProjectInput.setTimeValue ERROR>>');
                console.error(JSON.stringify(error));
            });
            
            //raises event of change made (intention is for parent object to recieve and calculate total hours)
            const evt = new CustomEvent('timeupdated', {
                detail: this.itemValue
            });
            this.dispatchEvent(evt);
            /**/
        }


        /*
        // a string
        const str = "#HelloWorld123$%";

        // regex expression to match all
        // non-alphanumeric characters in string
        const regex = /[^A-Za-z0-9]/g;

        // use replace() method to
        // match and remove all the
        // non-alphanumeric characters
        const newStr = str.replace(regex, "");

        console.log(newStr); // HelloWorld123
        */
    }
}