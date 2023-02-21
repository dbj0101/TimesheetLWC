import { LightningElement,api,track,wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import getUserDetails from '@salesforce/apex/TimeSheetComponentController.getUserDetails';
import fetchThisWeekDates from '@salesforce/apex/TimeSheetComponentController.fetchthisWeekDates';
import fetchCurrentProject from '@salesforce/apex/TimeSheetComponentController.fetchCurrentUserProjects';
import fetchCurrentUserTimeSheetData from '@salesforce/apex/TimeSheetComponentController.fetchCurrentUserTimeSheetData';
import addNewProjectMemberTimesheet from '@salesforce/apex/TimeSheetComponentController.addNewProjectMemberTimesheet';
import submitProjectTimeSheetData from '@salesforce/apex/TimeSheetComponentController.submitProjectTimeSheetData';
import deleteTimesheet from '@salesforce/apex/TimeSheetComponentController.deleteTimesheet'
import LOCALE from '@salesforce/i18n/locale';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class TimeSheetComponent extends LightningElement {

    @track error ;
    @api name;
    @track index = 0;
    @track localString ;
    weekStartingDay;
    weekEndingDay;
    formattedDate;
    selectedDate;
    @api dateListArray = [];
    @api dayListArray = [];
    @api dateDetailObject = [];
    @track projectDataList = [];
    @api selectedProject;
    @api jsonObj = {};
    @api objects = [];
    @api TotalHours = '0:00';
    @api day1Val;
    @api day2Val;
    @api day3Val;
    @api day4Val;
    @api day5Val;
    @api day6Val;
    @api day7Val;
    @track submitTrue = true;
    @track dataJSONStr;
    @api loaded = false;
    _title = 'Success';
    message = 'The Hours has been successfully submitted!';
    variant = 'success';
    setToReadOnly=true;


    connectedCallback() {
        console.log('callback');
        this.loaded=true;
        this.fetchCurrentUserDetails();
        this.fetchProjectTimeSheetData();
        this.fetchCurrentWeekDates();
        this.fetchUserProjectTimeSheetData();
    }

    handleProjectChange(event){
        this.selectedProject = event.target.value;
    }

    handleActiveTab(event)  {
        console.log('handleActiveTab event:'+event.target.value);
        //repopulate the Timesheet data just incase
        //if favorite has been marked then some new potintial TS
        if(event.target.value=='LogTime') {
            this.fetchUserProjectTimeSheetData();
        }
    }

    fetchCurrentUserDetails(){
        console.log('in current user details function');
        getUserDetails({userId : USER_ID}).then(result => {
           
            this.name = result.Name ;
            this.localeString = result.LocaleSidKey ;
        })
        .catch(error => {
            this.error = error;
        });
    }
    
    fetchCurrentWeekDates(){
        var shortDateoptions = { month: 'numeric', day: 'numeric'};
        var dayNameValues = {weekday: 'narrow'};

        let dayNameArr = [];

        if(this.selectedDate==null) {
            this.selectedDate=new Date();
        }
        this.dateListArray = [];
        console.log('selectedDate: '+this.selectedDate.toLocaleDateString()+" "+this.selectedDate.getFullYear()+" "+this.selectedDate.getMonth()+" "+this.selectedDate.getDate());
        //this.selectedDate.setDate(this.selectedDate.getDate()+20);
        fetchThisWeekDates({"inYear":this.selectedDate.getFullYear(), 
                            "inMonth":this.selectedDate.getMonth()+1, 
                            "inDay":this.selectedDate.getDate()}).then(result => {
            this.projectDataList = [];
            let dateObj = JSON.parse(result);
            this.dateDetailObject = dateObj;
            
            for (const key in dateObj) {
                if (dateObj.hasOwnProperty.call(dateObj, key)) {
                    //month only runs from 0-11 in this case
                    let weekDate = new Date(dateObj[key].year, dateObj[key].month-1, dateObj[key].day);
                    
                    let tempDate = new Date(weekDate.getFullYear(),weekDate.getMonth(),weekDate.getDate());
                    let formattedDate = new Intl.DateTimeFormat(LOCALE,shortDateoptions).format(tempDate);
                    let formattedDayVal = new Intl.DateTimeFormat(LOCALE,dayNameValues).format(tempDate);
                    dayNameArr.push(formattedDayVal);
                    this.dateListArray.push(formattedDate);
                    
                }
            }

            this.dayListArray = dayNameArr;
           
            var options = { month: 'long', day: 'numeric'};
            
            let weekDate = this.dateListArray[0];
            console.log("weekDate:"+weekDate);
            weekDate = new Date(weekDate);
            
            let tempDate = new Date(weekDate.getFullYear(),weekDate.getMonth(),weekDate.getDate());
            let formattedDate = new Intl.DateTimeFormat(LOCALE,options).format(tempDate);
            console.log("tempDate:"+tempDate);
            console.log("formattedDate:"+formattedDate);

            var options1 = { day: 'numeric'};

            let weekEndDate = this.dateListArray[this.dateListArray.length - 1];
            weekEndDate = new Date(weekEndDate);
            
            let tempDate1 = new Date(weekEndDate.getFullYear(),weekEndDate.getMonth(),weekEndDate.getDate());
            let weekEndFormattedDate = new Intl.DateTimeFormat(LOCALE,options1).format(tempDate1);

            console.log('weekEndFormattedDate>>');
            console.log(weekEndFormattedDate);
        
            this.weekStartingDay = formattedDate ;
            this.weekEndingDay = weekEndFormattedDate;
        });
    }


    fetchProjectTimeSheetData(){
        fetchCurrentProject({userId : USER_ID}).then(result => {
            let newList = JSON.parse(result);
            
            /* Below code will prepare the combo box options */
            var i;
            for(i = 0; i < newList.length; i++){
                const option = {
                    label : newList[i].label,
                    value : newList[i].value 
                };
                this.objects = [...this.objects, option];
            }
        }).catch(error => {
            this.error = error;
        });
    }

    fetchUserProjectTimeSheetData() {
        fetchCurrentUserTimeSheetData({"inYear":this.selectedDate.getFullYear(), 
                                        "inMonth":this.selectedDate.getMonth()+1, 
                                        "inDay":this.selectedDate.getDate()}).then(result =>{
            this.resetProjectDataList(result);
        }).catch(error => {
            console.log('ERROR fetchCurrentUserTimeSheetData: '+error.body.message);
            console.error(error);
            this.loaded=false;
        });
    }

    resetProjectDataList(strProjects) {
        //set the list of projects with timesheets for this week
        console.log('apex projects: '+strProjects);
        this.projectDataList = JSON.parse(strProjects);
        //if timesheets exist for the week place the current total hours into TotalHours
        if(this.projectDataList.length>0) {
            this.TotalHours = this.projectDataList[0].totalWeekHours;
        }
        else {
            this.TotalHours = '0:00';
        }
        this.loaded=false;
    }

    submitTimesheetEntry() {
        this.loaded = true;
        console.log('in submit button click');
        //console.log(JSON.stringify(this.projectDataList));
        
        //get all c-time-project-input items
        let finalDataArr = [];
        let listTpi=this.template.querySelectorAll('c-time-project-input');
        //read and sum itemValue field for each
        listTpi.forEach((item, index) => {
            //if object does not exist in array then create and add it into appropriate index
            if(finalDataArr[item.itemIndex]==undefined) {
                finalDataArr[item.itemIndex] = { "timesheetId":null, "projectName":null, "submitted":null, "day1":{ "idValue": null, "dataValue": null }, "day2":{ "idValue": null, "dataValue": null }, "day3":{ "idValue": null, "dataValue": null }, "day4":{ "idValue": null, "dataValue": null }, "day5":{ "idValue": null, "dataValue": null }, "day6":{ "idValue": null, "dataValue": null }, "day7":{ "idValue": null, "dataValue": null } };
            }
            //if project add projectId and Name to json
            //if day add Id, value(time entered) to json
            console.log('item.itemName:'+item.itemName+' ## itemValue:'+item.itemValue+' ## itemId:'+item.itemId+' ## index:'+item.itemIndex);
            try {
                if(item.itemName=='projectName') {
                    finalDataArr[item.itemIndex].timesheetId = item.itemId;
                    finalDataArr[item.itemIndex].projectName = item.itemValue;
                }
                else if(item.itemName=='day1') { 
                    console.log('day1 readOnly:'+item.readOnly);
                    finalDataArr[item.itemIndex].submitted = item.readOnly;
                    finalDataArr[item.itemIndex].day1.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day1.dataValue = item.itemValue;
                }
                else if(item.itemName=='day2') { 
                    finalDataArr[item.itemIndex].day2.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day2.dataValue = item.itemValue;
                }
                else if(item.itemName=='day3') { 
                    finalDataArr[item.itemIndex].day3.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day3.dataValue = item.itemValue;
                }
                else if(item.itemName=='day4') { 
                    finalDataArr[item.itemIndex].day4.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day4.dataValue = item.itemValue;
                }
                else if(item.itemName=='day5') { 
                    finalDataArr[item.itemIndex].day5.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day5.dataValue = item.itemValue;
                }
                else if(item.itemName=='day6') { 
                    finalDataArr[item.itemIndex].day6.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day6.dataValue = item.itemValue;
                }
                else if(item.itemName=='day7') { 
                    finalDataArr[item.itemIndex].day7.idValue = item.itemId;
                    finalDataArr[item.itemIndex].day7.dataValue = item.itemValue;
                }
            } catch(ex) {
                console.log('ERROR submitTimesheetEntry: '+error.message);
                console.error(error);
            }
        });
        let strJson = JSON.stringify(finalDataArr)
        console.log(strJson);

        //submit the timesheets to Database
        submitProjectTimeSheetData({timeSheetInput : strJson}).then(result => {
            //set the list of projects with timesheets for this week
            console.log('result>>');
            console.log(JSON.stringify(result));
            
            const evt = new ShowToastEvent({
                title: this._title,
                message: this.message,
                variant: this.variant,
            });
            this.dispatchEvent(evt);
            //should recieve back the projects now with submitted=true
            this.resetProjectDataList(result);
            this.loaded = false;
        }).catch(error => {
            this.error = error;
            const evt = new ShowToastEvent({
                title: "Error Submitting Timesheets",
                message: error.body.message,
                variant: "error",
            });
            this.dispatchEvent(evt);
            this.loaded = false;
        });
    }

    addTimeSheetEntry(){
        try {
            if(this.selectedProject==null || this.selectedProject=='') {
                const evtBlank = new ShowToastEvent({
                    title: "Error Adding Project",
                    message: "No project was selected.",
                    variant: "error"
                });
                this.dispatchEvent(evtBlank);
            } 
            else {
                this.loaded=true;
                addNewProjectMemberTimesheet({"projectId":this.selectedProject,
                                            "inYear":this.selectedDate.getFullYear(), 
                                            "inMonth":this.selectedDate.getMonth()+1, 
                                            "inDay":this.selectedDate.getDate()}).then(result =>{
                    //set the list of projects with timesheets for this week
                    this.resetProjectDataList(result);
                    //set project drop down to non-selected
                    const ddlProjectName = this.template.querySelector('.projectListClass');
                    console.log('ddlProjectName: '+ddlProjectName);
                    ddlProjectName.value='';
                    const evt = new ShowToastEvent({
                        title: "Project Added",
                        message: "Added the project to timesheet",
                        variant: "success"
                    });
                    this.dispatchEvent(evt);
                    this.loaded=false;
                }).catch(error => {
                    console.log('ERROR fetchCurrentUserTimeSheetData: '+error.message);
                    console.error(error);
                    let errorMsg = error.body.message;
                    if(errorMsg.includes('Duplicate timesheet')) {
                        errorMsg = 'Duplicate timesheet cannot be added or saved';
                    }
                    const evt = new ShowToastEvent({
                        title: "Error Adding Project",
                        message: errorMsg,
                        variant: "error"
                    });
                    this.dispatchEvent(evt);
                    this.loaded=false;
                });
            }
        }
        catch(ex) {
            console.log('ERROR: '+ex.message);
            console.error(ex);
        }
    }

    removeTimeSheetEntry(event){

        let projectDataArr = [];
        projectDataArr = this.projectDataList;
        let currentIndex = parseInt(event.target.dataset.index);
        console.log('event: '+JSON.stringify(event.target.dataset));
        console.log('currentIndex'+currentIndex);
        let proj=event.target.dataset.project;
        let tsId = event.target.dataset.timesheetid;
        console.log('tsId'+tsId);
        if(confirm(`Are you sure you want to remove the timesheet for ${proj} ?`)) {
            this.loaded=true;
            //projectDataArr.splice(currentIndex,1);
            //this.projectDataList = [...projectDataArr];
            deleteTimesheet({ "timesheetId":tsId }).then(result =>{
                this.resetProjectDataList(result);
                this.loaded=false;
            }).catch(error => {
                console.log('ERROR deleteTimesheet: '+error.body.message);
                console.error(error);
                this.loaded=false;
            });
        }
        
    }

    changeSelectedDate(event) {
        this.loaded=true;
        //console.log('changeSelectedDate event: '+event);
        let numDays=Number(event.target.dataset.factor);
        //console.log('numDays: '+numDays);
        ////console.log(typeof numDays);
        //console.log('selectedDate: '+this.selectedDate);
        this.selectedDate.setDate(this.selectedDate.getDate()+numDays);
        //console.log(this.selectedDate.toLocaleDateString());
        this.fetchCurrentWeekDates();
        this.fetchUserProjectTimeSheetData();
    }

    handleTimeUpdate(event) {
        console.log('handleTimeUpdate Event: '+event.detail);
        //get all c-time-project-input items
        let totalHoursMinutes=[0,0];
        let listTpi=this.template.querySelectorAll('c-time-project-input');
        //read and sum itemValue field for each
        listTpi.forEach((item, index) => {
            //console.log('item.itemName:'+item.itemName+' ## itemValue:'+item.itemValue+' ## itemId:'+item.itemId);
            //console.log('item.itemName.substring(0,3):'+item.itemName.substring(0,3));
            let val = item.itemValue.split(':');
            console.log('val:'+val);
            try {
                if(item.itemName.substring(0,3)=='day') {
                    totalHoursMinutes[0] += Math.floor(val[0]);
                    totalHoursMinutes[1] += Math.floor(val[1]);
                    //console.log('totalHoursMinutes:'+totalHoursMinutes);
                }
            } catch(ex) {}
        });
        //calculate total time with totals given
        let hoursStr=(Math.floor(Math.floor(totalHoursMinutes[1]) / 60)+Math.floor(totalHoursMinutes[0])).toString();
        let minutesStr=('0'+Math.floor(Math.floor(totalHoursMinutes[1] % 60))).slice(-2);
        //console.log('total hours:'+hoursStr+' ## total minutes:'+minutesStr);
        this.TotalHours=hoursStr+':'+minutesStr;
    }
    
}