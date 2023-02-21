public with sharing class TimeSheetComponentController {
    
    public class applicationException extends Exception {}
 	
    @AuraEnabled
    public static User getUserDetails(string userId){
        try {
            User currentUser = [SELECT Id,Name,LocaleSidKey FROM User WHERE Id =: userId WITH SECURITY_ENFORCED];
            return currentUser;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
        
    }

    public static Date getWeekStartDate(integer inYear, integer inMonth, integer inDay) {
        Date today = Date.newInstance(inYear, inMonth, inDay);
        System.debug('today:'+today+' ## startofweek:'+today.toStartOfWeek());
        if(today==today.toStartOfWeek()) {
            today = today.addDays(-1);
        }
        System.debug('today: '+today);
        return today.toStartOfWeek().addDays(1);
    }
    public static List<Date> getWeekDatesList(integer inYear, integer inMonth, integer inDay) {
        System.debug('inYear:'+inYear+' inMonth:'+inMonth+' inDay:'+inDay);
        try {
            //Date today = getWeekStartDate(inYear, inMonth, inDay);
            
            //Start week on Monday (hence why we subtracted a day when inDate was a Sunday)
            Date weekStart = getWeekStartDate(inYear, inMonth, inDay);//today.toStartofWeek().addDays(1);
            //Datetime dt = (DateTime)weekStart;
            //String weekStartDay = dt.format('E');
            
            Date weekEnd = weekStart.addDays(6);
            //Datetime dt1 = (DateTime)weekEnd;
            //String weekEndDay = dt1.format('E');
            
            Date weekDay2 = weekStart.addDays(1);
            //Datetime dt2 = (DateTime)weekDay2;
            //String weekDay2Day = dt2.format('E');
            
            Date weekDay3 = weekStart.addDays(2);
            //Datetime dt3 = (DateTime)weekDay3;
            //String weekDay3Day = dt3.format('E');

            Date weekDay4 = weekStart.addDays(3);
            //Datetime dt4 = (DateTime)weekDay4;
            //String weekDay4Day = dt4.format('E');

            Date weekDay5 = weekStart.addDays(4);
            //Datetime dt5 = (DateTime)weekDay5;
            //String weekDay5Day = dt5.format('E');

            Date weekDay6 = weekStart.addDays(5);
            //Datetime dt6 = (DateTime)weekDay6;
            //String weekDay6Day = dt6.format('E');

            return new list<Date>{weekStart, weekDay2, weekDay3, weekDay4, weekDay5, weekDay6, weekEnd};
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
    public static string ConvertToHoursText(Decimal minutes) {
        try {
            //TEXT(MFLOOR(Total_Minutes__c/60)) + ":" + RIGHT("0" + TEXT(MOD(Total_Minutes__c, 60)), 2)
            return Math.floor(minutes/60) + ':' + ('0' + Math.mod(integer.valueOf(minutes), 60)).right(2);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    //public static string fetchthisWeekDates(){
    public static string fetchthisWeekDates(integer inYear, integer inMonth, integer inDay){        
        try {
            Map<String,DateItem> weekDatesMap = new Map<String,DateItem>();

            List<Date> weekDatesList = getWeekDatesList(inYear, inMonth, inDay);
            
            weekDatesMap.put('day7', new DateItem(weekDatesList[6]));//new DateItem(weekEnd));
            weekDatesMap.put('day6', new DateItem(weekDatesList[5]));//new DateItem(weekDay6));
            weekDatesMap.put('day5', new DateItem(weekDatesList[4]));//new DateItem(weekDay5));
            weekDatesMap.put('day4', new DateItem(weekDatesList[3]));//new DateItem(weekDay4));
            weekDatesMap.put('day3', new DateItem(weekDatesList[2]));//new DateItem(weekDay3));
            weekDatesMap.put('day2', new DateItem(weekDatesList[1]));//new DateItem(weekDay2));
            weekDatesMap.put('day1', new DateItem(weekDatesList[0]));//new DateItem(weekStart));
            
    
            string weekDatesStr = JSON.serialize(weekDatesMap);
            
            return weekDatesStr;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
        
    }

    @AuraEnabled
    public static string fetchCurrentUserProjects(string userId){
        List<ListViewItem> projectNameList = new List<ListViewItem>();
        
        try {
            List<Project_Member__c> currentProjectMembers = [SELECT Id,Member__c,Project__c,Project__r.Name,Name,Favorite__c FROM Project_Member__c 
                                                             WHERE Member__c =:userId  
                                                             WITH SECURITY_ENFORCED];
            
            for (Project_Member__c pMember : currentProjectMembers) {
                ListViewItem lvi = new ListViewItem();
                lvi.value=pMember.Project__c;
                lvi.label=pMember.Project__r.Name;
                //projectNameList.add(pMember.Project__r.Name);
                projectNameList.add(lvi);
                
            }          
            //try { insertMissingFavoriteTimesheets(currentProjectMembers); } atch(Exception ex) { System.debug('ERROR - '+ex);}
            insertMissingFavoriteTimesheets(currentProjectMembers);
            return JSON.serialize(projectNameList);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string fetchCurrentUserTimeSheetData(integer inYear, integer inMonth, integer inDay) {
        try {
        	string userId = userinfo.getUserId();
            //Get Timesheets for user and start of week
            Date weekStart = getWeekStartDate(inYear, inMonth, inDay);
            System.debug('weekStart:'+weekStart);
            //setup to get total time
            Decimal decTotalMin=0;
            //get each timesheet (probably a map with a TimesheetId and data just pulled
            Map<Id, Timesheet__c> mapIdToTimesheet = new Map<Id, Timesheet__c>();
            Map<Id, List<Timesheet_Item__c>> mapTimesheetIdToItemList = new Map<Id, List<Timesheet_Item__c>>();
            for(Timesheet__c ts: [select Id, Name, Member__c, Project__c, Project__r.Name, Date_Week_Start__c, 
                                  Date_Week_End__c, Employee_Submitted__c, Total_Minutes__c
                                  from Timesheet__c where  Member__c=:userId 
                                  and Date_Week_Start__c=:weekStart WITH SECURITY_ENFORCED]) 
            {
                mapIdToTimesheet.put(ts.Id, ts);
                System.debug('Added to mapIdToTimesheet:'+ts);
                decTotalMin=decTotalMin+ts.Total_Minutes__c;
                System.debug('Timesheet Total Minutes: '+ts.Total_Minutes__c);
            }
            System.debug('Timesheet WEEK total minutes: '+decTotalMin);
            String strTotalHours = ConvertToHoursText(decTotalMin);
            System.debug('Timesheet WEEK total hours text: '+strTotalHours);
            //declare the map that will return JSON string
            //Map<String, TimesheetItem> mapRetJson = new Map<String, TimesheetItem>();
            List<TimesheetItem> listRetJson = new List<TimesheetItem>();
            //find and record timesheet items into map of timesheetId and List of timesheetitems
            if(mapIdToTimesheet.size()>0) {
                for(Timesheet_Item__c tsi :[select Id, Name, Timesheet__c, Hours_Text__c, Logged_Date__c 
                                            from Timesheet_Item__c where Timesheet__c in :mapIdToTimesheet.keySet()
                                            WITH SECURITY_ENFORCED
                                            order by Timesheet__c, Logged_Date__c ])
                {                          
                    if(!mapTimesheetIdToItemList.containsKey(tsi.Timesheet__c)) {
                        List<Timesheet_Item__c> ltsi = new List<Timesheet_Item__c>();
                        ltsi.add(tsi);
                        mapTimesheetIdToItemList.put(tsi.Timesheet__c, ltsi);
                        System.debug('NEW MAP ITEM:'+tsi);
                    }
                    else {
                        mapTimesheetIdToItemList.get(tsi.Timesheet__c).add(tsi);
                        System.debug('Added to map:'+tsi);
                    }
                }
                //build return xml
                integer projectCount=0;
                for(Id tsId:mapIdToTimesheet.keySet()) {
                    //JIC but there SHOULD never be a case of a missing timesheet (famous last words there)
                    if(mapTimesheetIdToItemList.containsKey(tsId)) {
                        Timesheet__c ts = mapIdToTimesheet.get(tsId);
                        TimesheetItem ti = new TimesheetItem();
                        ti.timesheetId = ts.Id;
                        ti.projectId = ts.Project__c;
                        ti.projectName = ts.Project__r.Name;
                        ti.submitted = ts.Employee_Submitted__c;
                        ti.totalWeekHours = strTotalHours;
                        //ti.dataValues = new List<dataIdValue>();
                        
                        Map<Date, DataIdValue> mapDateToDataIdValue = new Map<Date, DataIdValue>();
                        Date currentDate = ts.Date_Week_Start__c;
                        //Check if there are any missing Dates and insert them if so
                        if(mapTimesheetIdToItemList.get(tsId).size()<7) {
                            set<Date> setDates = new set<Date>();
                            for(Timesheet_Item__c tic :mapTimesheetIdToItemList.get(tsId)) {
                                System.debug('Missing Timesheet_Item__c somewhere: '+tic);
                                setDates.add(tic.Logged_Date__c);
                            }
                            currentDate = ts.Date_Week_Start__c;
                            while(currentDate<=ts.Date_Week_End__c) {
                                if(!setDates.contains(currentDate)) {
                                    Timesheet_Item__c tiNew = new Timesheet_Item__c();
                                    tiNew.Timesheet__c = ts.Id;
                                    tiNew.Logged_Date__c = currentDate;
                                    tiNew.Hours_Text__c = '0:00';
                                    mapTimesheetIdToItemList.get(tsId).add(tiNew);
                                }
                                currentDate = currentDate.addDays(1);
                            }
                            upsert mapTimesheetIdToItemList.get(tsId);
                            for(Timesheet_Item__c tic :mapTimesheetIdToItemList.get(tsId)) { System.debug('Recently Added Timesheet_Item__c:'+tic); }
                        }
                        
                        //Build out full weeks items as empty first then fill them in with Timesheet_Item__c's returned
                        currentDate = ts.Date_Week_Start__c;
                        while(currentDate<=ts.Date_Week_End__c) {
                            DataIdValue div = new DataIdValue();
                            div.dateValue = String.valueOf(currentDate);
                            System.debug('DATE: '+string.valueof(currentDate));
                            System.debug('mapDateToDataIdValue add:'+div);
                            mapDateToDataIdValue.put(currentDate, div);
                            currentDate=currentDate.addDays(1);
                        }
                        //fill in with Timesheet_Item__c's returned
                        for(Timesheet_Item__c tic :mapTimesheetIdToItemList.get(tsId)) {
                            if(mapDateToDataIdValue.containsKey(tic.Logged_Date__c)) {
                                mapDateToDataIdValue.get(tic.Logged_Date__c).idValue = String.valueOf(tic.Id);
                                mapDateToDataIdValue.get(tic.Logged_Date__c).dataValue = String.valueof(tic.Hours_Text__c);
                                System.debug('Set DataValue to Hours:'+mapDateToDataIdValue.get(tic.Logged_Date__c));
                            } else {System.debug('tic.Logged_Date not in map:'+tic.Logged_Date__c);}
                        }
                        
                        //Add mapped DataIdValue's to mapDateToDataIdValue.dateValue
                        currentDate=ts.Date_Week_Start__c;
                        integer i = 1;
                        while(currentDate<=ts.Date_Week_End__c) {
                            //ti.dataValues.add(mapDateToDataIdValue.get(currentDate));
                            if(i==1) { ti.day1=mapDateToDataIdValue.get(currentDate); }
                            else if(i==2) { ti.day2=mapDateToDataIdValue.get(currentDate); }
                            else if(i==3) { ti.day3=mapDateToDataIdValue.get(currentDate); }
                            else if(i==4) { ti.day4=mapDateToDataIdValue.get(currentDate); }
                            else if(i==5) { ti.day5=mapDateToDataIdValue.get(currentDate); }
                            else if(i==6) { ti.day6=mapDateToDataIdValue.get(currentDate); }
                            else if(i==7) { ti.day7=mapDateToDataIdValue.get(currentDate); }
                            i=i+1;
                            currentDate=currentDate.addDays(1);
                        }
                        if(Test.isRunningTest()) {
                            System.debug('ti:'+ti);
                            System.debug('ti.day1:'+ti.day1);
                            System.debug('ti.day2:'+ti.day2);
                            System.debug('ti.day3:'+ti.day3);
                            System.debug('ti.day4:'+ti.day4);
                            System.debug('ti.day5:'+ti.day5);
                            System.debug('ti.day6:'+ti.day6);
                            System.debug('ti.day7:'+ti.day7);
                        }
                        //mapRetJson.put('proj'+projectCount, ti);
                        listRetJson.add(ti);
                        projectCount=projectCount+1;
                    }//if(mapTimesheetIdToItemList.containsKey(tsId))
                }//for(Id tsId:mapIdToTimesheet.keySet())
            }//if(mapIdToTimesheet.size()>0)
            
            
            
            //return JSON.serialize(mapRetJson);
            return JSON.serialize(listRetJson);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }//public static string fetchCurrentUserTimeSheetData()

    @AuraEnabled
    public static string addNewProjectMemberTimesheet(string projectId, integer inYear, integer inMonth, integer inDay) {
        try {
        	string userId = userinfo.getUserId();
            //Get Timesheets for user and start of week
            Date weekStart = getWeekStartDate(inYear, inMonth, inDay);
            System.debug('weekStart:'+weekStart);
            Timesheet__c ts = new Timesheet__c();
            ts.Project__c=projectId;
            ts.Member__c=UserInfo.getUserId();
            ts.Date_Week_Start__c=weekStart;
            insert ts;
            System.debug(ts);
        	return fetchCurrentUserTimeSheetData(inYear, inMonth, inDay);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string submitProjectTimeSheetData(string timeSheetInput){
        try {
            ////Here is what the JSON should look like, should fit right into TimesheetItem class
            //string sJson = '[{"timesheetId":"a037e00000685ZcAAI","projectName":"projectName","day1":{"idValue":"a027e000005REtlAAG","dataValue":"1:00"},"day2":{"idValue":"a027e000005REtmAAG","dataValue":"1:00"},"day3":{"idValue":"a027e000005REtnAAG","dataValue":"1:00"},"day4":{"idValue":"a027e000005REtoAAG","dataValue":"1:00"},"day5":{"idValue":"a027e000005REtpAAG","dataValue":"1:00"},"day6":{"idValue":"a027e000005REtqAAG","dataValue":"1:00"},"day7":{"idValue":"a027e000005REtrAAG","dataValue":"1:00"}},{"timesheetId":"a037e00000688VhAAI","projectName":"projectName","day1":{"idValue":"a027e000005RLrvAAG","dataValue":"2:00"},"day2":{"idValue":"a027e000005RLrwAAG","dataValue":"2:00"},"day3":{"idValue":"a027e000005RLrxAAG","dataValue":"2:00"},"day4":{"idValue":"a027e000005RLryAAG","dataValue":"2:00"},"day5":{"idValue":"a027e000005RLrzAAG","dataValue":"2:00"},"day6":{"idValue":"a027e000005RLs0AAG","dataValue":"2:00"},"day7":{"idValue":"a027e000005RLs1AAG","dataValue":"2:00"}}]';
            //TimeSheetComponentController.TimesheetItem
            Date retValDate;
            List<TimesheetItem> listTsi=(List<TimesheetItem>) JSON.deserializeStrict(timeSheetInput, List<TimesheetItem>.class);
            List<Timesheet__c> listTimesheetUpdate = new List<Timesheet__c>();
            List<Timesheet_Item__c> listTimesheetItemUpdate = new List<Timesheet_Item__c>();
            Map<Id, string> mapTimesheetItemIdToDateString = new Map<Id, String>();
            Set<Id> setTimesheetId = new Set<Id>();
            //Parse out input JSON into object arrays
            for(TimesheetItem tsi :listTsi) {
                setTimesheetId.add(tsi.timesheetId);
                mapTimesheetItemIdToDateString.put(tsi.day1.idValue, tsi.day1.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day2.idValue, tsi.day2.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day3.idValue, tsi.day3.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day4.idValue, tsi.day4.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day5.idValue, tsi.day5.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day6.idValue, tsi.day6.dataValue);
                mapTimesheetItemIdToDateString.put(tsi.day7.idValue, tsi.day7.dataValue);
            }
            //update any timesheet_Item__c fields that have changed but not updated (should be none but just in case)
            try {
                for(Timesheet_Item__c tItem :[select Id, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__r.Employee_Submitted__c=false and Id in :mapTimesheetItemIdToDateString.KeySet()]) {
                    if(mapTimesheetItemIdToDateString.ContainsKey(tItem.Id)) {
                        if(tItem.Hours_Text__c != mapTimesheetItemIdToDateString.get(tItem.Id)) {
                            Timesheet_Item__c updateItem = new Timesheet_Item__c();
                            updateItem.Id = tItem.Id;
                            updateItem.Hours_Text__c = mapTimesheetItemIdToDateString.get(tItem.Id);
                            listTimesheetItemUpdate.add(updateItem);
                        }
                    }//if(mapTimesheetItemIdToDateString.ContainsKey(tItem.Id))
                }//for(Timesheet_Item__c tItem :[select Id, Hours_Text__c from Timesheet_Item__c where Id in :mapTimesheetItemIdToDateString.KeySet()])
                if(listTimesheetItemUpdate.size()>0) {
                    update listTimesheetItemUpdate;
                }
            } catch(Exception ex1) { System.debug('TimeSheetComponentController.submitProjectTimeSheetData INNER ERROR:'+ex1.getMessage()); System.debug(ex1); }
            //Get Timesheets given make sure the total time is greater than 40 hours (2,400 minutes) set to submitted if true
            Date DateWeek;
            Decimal decTotalMin = 0;
            AggregateResult aggRes = [select sum(Total_Minutes__c)timeTotal from Timesheet__c where Id in :setTimesheetId];
            System.debug('aggRes:'+aggRes);
            if(aggRes.get('timeTotal') != null) {
                decTotalMin = decimal.valueOf(string.valueOf(aggRes.get('timeTotal')));
            }
            for(Timesheet__c ts: [select Id, Name, Employee_Submitted__c, Employee_Submitted_Date__c, Total_Minutes__c, Date_Week_Start__c
                                  from Timesheet__c where Employee_Submitted__c=false and Id in :setTimesheetId 
                                  WITH SECURITY_ENFORCED]) 
            {
                listTimesheetUpdate.add(ts);
                DateWeek = ts.Date_Week_Start__c;
            }
            
            //check if there are any updates to be made
            if(listTimesheetUpdate.size()<=0){
                //Throw exeption
                throw new applicationException('No new timesheets submitted');
            }
            //40 hours or more
            else if(decTotalMin<2400) {
                //Throw exeption
                throw new applicationException('Total hours are not 40 or more');
            }//if(decTotalMin<2400)
            else {
                for(Timesheet__c ts :listTimesheetUpdate) {
                    ts.Employee_Submitted__c = true;
                    ts.Employee_Submitted_Date__c = Datetime.now();
                }
                update listTimesheetUpdate;
                return fetchCurrentUserTimeSheetData(DateWeek.year(), DateWeek.month(), DateWeek.day());
            }//else if(decTotalMin<2400)
        }catch (Exception e) { System.debug(e.getMessage()+'>>>'+e.getLineNumber()); throw new AuraHandledException(e.getMessage()); }
        
        /* REMOVE for now
        List<Timesheet__c> timeSheetList = new List<Timesheet__c>();
        Map<string,Id> projectNameAndIdMap = new Map<string,Id>();
        string userId = userinfo.getUserId();        
        try {
            List<Project_Member__c> currentProjectList = [SELECT Id,Member__c,Project__c,Project__r.Name,Name FROM Project_Member__c 
                                                             WHERE Member__c =:userId  
                                                             WITH SECURITY_ENFORCED];
            for(Project_Member__c pm : currentProjectList){
                projectNameAndIdMap.put(pm.Project__r.Name,pm.Project__c);
            }

            List<TimeSheetDataWrapper> parsedData = (List<TimeSheetDataWrapper>)JSON.deserialize(timeSheetInput,List<TimeSheetDataWrapper>.class);
            for(TimeSheetDataWrapper dataWrapper : parsedData){
                if(!dataWrapper.dataValues.isEmpty()){
                    Timesheet__c newRecord = new Timesheet__c();
                    newRecord.Project__c = projectNameAndIdMap.containsKey(dataWrapper.projectName) ? projectNameAndIdMap.get(dataWrapper.projectName) : NULL;
                    newRecord.Member__c = userinfo.getUserId();
                    timeSheetList.add(newRecord);
                    for(DataValues dv : dataWrapper.dataValues){
                        //Create new timesheet_item
                        //add hours and record above to MAP
                        
                        //newRecord.Logged_Date__c = Date.valueOf(dv.dateValue);
                        //newRecord.Hours__c = Decimal.valueOf(dv.value);
                    }
                }
            }

        
            if(!timeSheetList.isEmpty() && Schema.sObjectType.Timesheet__c.isCreateable()){
                
                insert timeSheetList;
            }

        } catch (Exception e) { System.debug(e.getMessage()+'>>>'+e.getLineNumber()); throw new AuraHandledException(e.getMessage()); } */
    }
    
    @AuraEnabled
    public static string setTimeValue(Id timeSheetItemId, string hours) {
        try {
            Timesheet_Item__c tsi = new Timesheet_Item__c();
            tsi.Id = timeSheetItemId;
            tsi.Hours_Text__c = hours;
            update tsi;
            string returnHours = [select Timesheet__r.Total_Hours_Text__c from Timesheet_Item__c where Id=:timeSheetItemId limit 1][0].Timesheet__r.Total_Hours_Text__c;
            return returnHours;
        } catch (Exception e) { System.debug(e.getMessage()+'>>>'+e.getLineNumber()); throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string deleteTimesheet(string timesheetId) {
        try {
            Timesheet__c ts = [select Id, Name, Date_Week_Start__c from Timesheet__c where Id=:timesheetId];
            Date dt = ts.Date_Week_Start__c;
            System.debug('Deleting timesheet:'+ts);
            delete ts;
        	return fetchCurrentUserTimeSheetData(dt.year(), dt.month(), dt.day());
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    ////BEGIN - datatableStar methods

    @AuraEnabled
    public static string fetchCurrentUserProjectList(string userId){
        
        List<ProjectItem> projectNameList = new List<ProjectItem>();
        
        try {
            List<Project_Member__c> currentProjectMembers = [SELECT Id,Member__c,Project__c,Project__r.Name,Name,Favorite__c 
                                                             FROM Project_Member__c 
                                                             WHERE Member__c =:userId
                                                             WITH SECURITY_ENFORCED];
            
            for (Project_Member__c pMember : currentProjectMembers) {
                ProjectItem pItem = new ProjectItem();
                pItem.projectMemberId = pMember.Id;
                pItem.projectName = pMember.Project__r.Name;
                pItem.favorite = pMember.Favorite__c;
                projectNameList.add(pItem);
            }          
           
            return JSON.serialize(projectNameList);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string setProjectFavorite(string projectMemberId, boolean favorite){
        try {
            Project_Member__c pm;
            for(Project_Member__c item :[select Id, Name, Project__c, Member__c, Favorite__c from Project_Member__c where Id=:projectMemberId]) {
                pm = item;
            }
            if(pm != null) {
                pm.Favorite__c = favorite;
                update pm;
                if(favorite) {
                    List<Project_Member__c> lpm = new List<Project_Member__c>();
                    lpm.add(pm);
                    return insertMissingFavoriteTimesheets(lpm);
                }
                else {
                    return 'Success';
                }
            }//if(pm != null)
            else { return 'Project not found'; }
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    public static string insertMissingFavoriteTimesheets(List<Project_Member__c> listPm) {
        //populate the set of dates this week and next week
        set<Date> setDates = new set<Date>();
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        setDates.add(dt);
        setDates.add(dt.addDays(7));
        //populate the set of members and projects
        set<Id> setMemberId = new set<Id>();
        set<Id> setProjectId = new set<Id>();
        for(Project_Member__c pm :listPm) {
            setMemberId.add(pm.Member__c);
            setProjectId.add(pm.Project__c);
        }
        System.debug('insertMissingFavoriteTimesheets setDates:'+setDates);
        System.debug('insertMissingFavoriteTimesheets setMemberId:'+setMemberId);
        System.debug('insertMissingFavoriteTimesheets setProjectId:'+setProjectId);
        
        //populate map of all current timesheets for projects, members, and dates
        Map<Date, List<Timesheet__c>> mapDateToListTimesheet = new Map<Date, List<Timesheet__c>>();
        for(Timesheet__c ts :[select Id, Name, Project__c, Member__c, Date_Week_Start__c 
                              from Timesheet__c
                              where Date_Week_Start__c in :setDates
                              and Project__c in :setProjectId
                              and Member__c in :setMemberId]) 
        {
            if(mapDateToListTimesheet.containsKey(ts.Date_Week_Start__c)) {
                mapDateToListTimesheet.get(ts.Date_Week_Start__c).add(ts);
            }
            else {
                List<Timesheet__c> listTs = new List<Timesheet__c>();
                listTs.add(ts);
                mapDateToListTimesheet.put(ts.Date_Week_Start__c, listTs);
            }
        }
        System.debug('insertMissingFavoriteTimesheets mapDateToListTimesheet:'+mapDateToListTimesheet);
        //for each listPm and setDates check if in mapDateToListTimesheet
        List<Timesheet__c> listTimesheetInsert = new List<Timesheet__c>();
        for(Project_Member__c pm :listPm) {
            if(pm.Favorite__c) {
                //if IS present move to next pm
                for(Date dte :setDates) {
                    boolean nextDate=false;
                    if(mapDateToListTimesheet.containsKey(dte)) {
                        for(Timesheet__c ts  :mapDateToListTimesheet.get(dte)) {
                            if(pm.Project__c==ts.Project__c && pm.Member__c==ts.Member__c) {
                                //Match found
                                System.debug('insertMissingFavoriteTimesheets MATCH FOUND pm:'+pm);
                                System.debug('insertMissingFavoriteTimesheets MATCH FOUND ts:'+ts);
                                nextDate = true;
                            }
                            if(nextDate) {
                                break;
                            }
                        }//for(Timesheet__c ts  :mapDateToListTimesheet.get(dte))
                    }//if(mapDateToListTimesheet.containsKey(dte))
                    //if(nextDate) {
                    //    break;
                    //}
                    //if not present then create timesheet and add to insert List
                    if(!nextDate) {
                        Timesheet__c ts = new Timesheet__c();
                        ts.Project__c = pm.Project__c;
                        ts.Member__c = pm.Member__c;
                        ts.Date_Week_Start__c = dte;
                        System.debug('insertMissingFavoriteTimesheets noMatchFound:'+ts);
                        listTimesheetInsert.add(ts);
                    }
                }//for(Date dte :setDates)
            }
        }//for(Project_Member__c pm :listPm)
        
        if(listTimesheetInsert.size()>0) {
            for(Timesheet__c ts :listTimesheetInsert) {
                System.debug('insertMissingFavoriteTimesheets Add Ts:'+ts);
            }
            insert listTimesheetInsert;
        }        
        
        return 'Success';
    }

    ////END - datatableStar methods
    
    public class ListViewItem {
        public String value;
        public String label;
    }

    public class ProjectItem {
        public string projectMemberId;
        public string projectName;
        public boolean favorite; 
    }

    public class TimeSheetDataWrapper{
        public String projectName;
        public List<DataValues> dataValues;
    }
    
    public class DataValues {
        public String value;
        public String dateValue;
        
    }
	
    public class TimesheetItem {
        public String timesheetId;
        public String projectId;
        public String projectName;
        public boolean submitted;
        public String totalWeekHours;
        public DataIdValue day1;
        public DataIdValue day2;
        public DataIdValue day3;
        public DataIdValue day4;
        public DataIdValue day5;
        public DataIdValue day6;
        public DataIdValue day7;
    }
    public class DataIdValue {
        public String idValue;
        public String dataValue;
        public String dateValue;
    }
    
    /*public class TimesheetItem1 {
        public String projectId;
        public String projectName;
        public List<DataIdValue> dataValues;
    }
    public class DataIdValue1 {
        public String idValue;
        public String dataValue;
        public DateItem dateValue;
    }*/
    public class DateItem {
        public String year;
        public String month;
        public String day;

        //public DateItems() {}
        public DateItem(Date inDate) {
            this.year = String.valueOf(inDate.year());
            this.month = String.valueOf(inDate.month());
            this.day = String.valueOf(inDate.day());
        }
    }

}