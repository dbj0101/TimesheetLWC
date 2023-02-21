@isTest(seeAllData = false)
public with sharing class Test_TimeSheetComponentController {
    @TestSetup
    static void createData(){
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';
        prj.Status__c='Not Started';
        insert prj;

        Project_Member__c prjm = new Project_Member__c();
        prjm.Member__c = userinfo.getUserId();
        prjm.Project__c = prj.Id;
        insert prjm;

    }
    static void insertSecondProject(){
        Project__c prj = new Project__c();
        prj.Name = 'Test Project Two';
        prj.Status__c='Not Started';
        insert prj;

        Project_Member__c prjm = new Project_Member__c();
        prjm.Member__c = userinfo.getUserId();
        prjm.Project__c = prj.Id;
        insert prjm;
    }
	
    @IsTest
    static void fetchCurrentUserDetails(){
        
        Test.startTest();
        User usr = TimeSheetComponentController.getUserDetails(userinfo.getUserId());
        System.assertEquals(usr.Id != null,true,'user exists');
        Test.stopTest();
        
    }

    @IsTest
    static void fetchCurrentWeekDates(){
        
        Test.startTest();
        Date dt = Date.newInstance(2021, 3, 14);//make it a Sunday for 1 extra line
        String currWeekStr = TimeSheetComponentController.fetchthisWeekDates(dt.year(), dt.month(), dt.day());
        Map<string,Object> dateMap = (Map<string,Object>)JSON.deserializeUntyped(currWeekStr);
        System.assertEquals(dateMap.isEmpty(), false,'Got the Dates');
        Test.stopTest();
        
    }

    @IsTest
    static void fetchCurrentProjects(){
        
        Test.startTest();
        String projectListStr = TimeSheetComponentController.fetchCurrentUserProjects(userinfo.getUserId());
        System.debug('fetchCurrentProjects():'+projectListStr);
        System.assertEquals(projectListStr != null, true,'projects exist');
        Test.stopTest();
        
    }
    
    @IsTest
    static void fetchCurrentProjectTimesheets() {
        //fetchCurrentUserTimeSheetData
        Project__c prj = [select Id, Name from Project__c limit 1];
        Project_Member__c pmb = [select Id, Name, Member__c, Project__c from Project_Member__c where Project__c=:prj.Id limit 1];
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=prj.Id;
        ts.Member__c=pmb.Member__c;
        ts.Date_Week_Start__c=dt;
        insert ts;
        integer i=1;
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c from Timesheet_Item__c where Timesheet__c=:ts.Id]) {
            tsi.Hours_Text__c = ''+i+':00';
            System.debug('tsiItem: '+tsi);
            listTsi.add(tsi);
            i=i+1;
        }
        update listTsi;
        delete listTsi[2];
        Test.startTest();
        String projTimesheetList = TimeSheetComponentController.fetchCurrentUserTimeSheetData(dt.year(), dt.month(), dt.day());
        System.debug('fetchCurrentProjectTimesheets - projTimesheetList: ##FollowingLine##');
        System.debug(projTimesheetList);
        System.assertEquals(projTimesheetList != null, true, 'Timesheets exist');
        Test.stopTest();
    }
    
    @IsTest
    static void testSetTimeValue() {
        Project__c prj = [select Id, Name from Project__c limit 1];
        Project_Member__c pmb = [select Id, Name, Member__c, Project__c from Project_Member__c where Project__c=:prj.Id limit 1];
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=prj.Id;
        ts.Member__c=pmb.Member__c;
        ts.Date_Week_Start__c=dt;
        insert ts;
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c from Timesheet_Item__c where Timesheet__c=:ts.Id]) {
            System.debug('tsiItem: '+tsi);
            listTsi.add(tsi);
        }
        Test.startTest();
        System.assert(listTsi.size()==7, '7 Timesheet items have not been added to Timesheet');
        string retVal = TimeSheetComponentController.setTimeValue(listTsi[0].Id, '4:30');
        string sHours=[select Hours_Text__c from Timesheet_Item__c where Id=:listTsi[0].Id][0].Hours_Text__c;
        System.debug('sHours:'+sHours);
        System.debug('retVal:'+retVal);
        System.assertEquals(sHours, '4:30', 'TimeSheetComponentController.setTimeValue() not working correctly');
        System.assertEquals(retVal, '4:30', 'TimeSheetComponentController.setTimeValue() did not return correct value');
        retVal = TimeSheetComponentController.setTimeValue(listTsi[1].Id, '5:30');
        System.debug('retVal Round2:'+retVal);
        System.assertEquals(retVal, '10:00', 'TimeSheetComponentController.setTimeValue() did not return correct value');
        Test.stopTest();
    }
    
    @IsTest
    static void testAddNewProjectMemberTimesheet() {
        Project__c prj = [select Id, Name from Project__c limit 1];
        Project_Member__c pmb = [select Id, Name, Member__c, Project__c from Project_Member__c where Project__c=:prj.Id limit 1];
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=prj.Id;
        ts.Member__c=pmb.Member__c;
        ts.Date_Week_Start__c=dt;
        insert ts;
        insertSecondProject();
        
        prj = [select Id, Name from Project__c where Name='Test Project Two' limit 1];
        dt = Date.today();
        //dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Test.startTest();
        String projTimesheetList = TimeSheetComponentController.addNewProjectMemberTimesheet(prj.Id, dt.year(), dt.month(), dt.day());
        System.debug('testAddNewProjectMemberTimesheet():'+projTimesheetList);
        List<TimeSheetComponentController.TimesheetItem> listTi = (List<TimeSheetComponentController.TimesheetItem>) JSON.deserializeStrict(projTimesheetList, List<TimeSheetComponentController.TimesheetItem>.class);
        System.debug('listTi.size():'+listTi.size());
        for(TimeSheetComponentController.TimesheetItem ti :listTi) { System.debug(ti); }
        System.assertEquals(2, listTi.size(), 'Timesheets count is not 2');
        Test.stopTest();
    }
    
    @IsTest
    static void testConvertToHoursText() {
        String str = TimeSheetComponentController.ConvertToHoursText(191);
        System.debug('testConvertToHoursText str:'+str);
        System.assertEquals('3:11', str, 'testConvertToHoursText result should have been 3 hours 11 minutes');
    }
    
    @IsTest
    static void testSubmitTimesheets() {
        //submitProjectTimeSheetData
        insertSecondProject();
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        List<Project__c> listPrj = [select Id, Name from Project__c];
        List<Timesheet__c> listTs = new List<Timesheet__c>();
        for(Project_Member__c pmb :[select Id, Name, Member__c, Project__c, Project__r.Id from Project_Member__c where Project__c in :listPrj]) {
            Timesheet__c ts = new Timesheet__c();
            ts.Project__c=pmb.Project__r.Id;
            ts.Member__c=pmb.Member__c;
            ts.Date_Week_Start__c=dt;
            listTs.add(ts);
        }
        insert(listTs);
        integer i = 0;
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        Map<Id, List<TimesheetComponentController.DataIdValue>> mapTimesheetIdToListValues = new Map<Id, List<TimesheetComponentController.DataIdValue>>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c, Timesheet__c, Timesheet__r.Id from Timesheet_Item__c where Timesheet__c in :listTs]) {
            //tsi.Hours_Text__c = '3:00';
            tsi.Hours_Text__c = ''+i+':00';
            i=i+1;
            System.debug('tsiItem: '+tsi);
            listTsi.add(tsi);
            if(mapTimesheetIdToListValues.containskey(tsi.Timesheet__r.Id)) {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                mapTimesheetIdToListValues.get(tsi.Timesheet__r.Id).add(val);
            }
            else {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                List<TimesheetComponentController.DataIdValue> lst = new List<TimesheetComponentController.DataIdValue>();
                lst.add(val);
                mapTimesheetIdToListValues.put(tsi.Timesheet__r.Id, lst);
            }
        }
        update listTsi;
        List<TimesheetComponentController.TimesheetItem> listItem = new List<TimesheetComponentController.TimesheetItem>();
        for(Id tsId :mapTimesheetIdToListValues.keyset()) {
            TimesheetComponentController.TimesheetItem item = new TimesheetComponentController.TimesheetItem();
            item.timesheetId = tsId;
            item.day1=mapTimesheetIdToListValues.get(tsId)[0];
            item.day2=mapTimesheetIdToListValues.get(tsId)[1];
            item.day3=mapTimesheetIdToListValues.get(tsId)[2];
            item.day4=mapTimesheetIdToListValues.get(tsId)[3];
            item.day5=mapTimesheetIdToListValues.get(tsId)[4];
            item.day6=mapTimesheetIdToListValues.get(tsId)[5];
            item.day7=mapTimesheetIdToListValues.get(tsId)[6];
            //change one value to test the update works properly
            item.day1.dataValue = '4:30';
            listItem.add(item);
            system.debug('Test: added item:'+item);
        }
        string strJson = JSON.serialize(listItem);
        Test.startTest();
        TimesheetComponentController.submitProjectTimeSheetData(strJson);
        List<Timesheet__c> listTsCheck = [select Id, Name, Employee_Submitted__c, Employee_Submitted_Date__c, Total_Minutes__c
                                  			from Timesheet__c where Employee_Submitted__c=true];
        for(Timesheet__c ts :listTsCheck) { System.debug('TEST  - Timesheet Check:'+ts); }
        System.assertEquals(2, listTsCheck.size(), 'Timesheets submitted should be 2');
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitTimesheetsHoursLessthan40() {
        //submitProjectTimeSheetData
        insertSecondProject();
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        List<Project__c> listPrj = [select Id, Name from Project__c];
        List<Timesheet__c> listTs = new List<Timesheet__c>();
        for(Project_Member__c pmb :[select Id, Name, Member__c, Project__c, Project__r.Id from Project_Member__c where Project__c in :listPrj]) {
            Timesheet__c ts = new Timesheet__c();
            ts.Project__c=pmb.Project__r.Id;
            ts.Member__c=pmb.Member__c;
            ts.Date_Week_Start__c=dt;
            listTs.add(ts);
        }
        insert(listTs);
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        Map<Id, List<TimesheetComponentController.DataIdValue>> mapTimesheetIdToListValues = new Map<Id, List<TimesheetComponentController.DataIdValue>>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c, Timesheet__c, Timesheet__r.Id from Timesheet_Item__c where Timesheet__c in :listTs]) {
            tsi.Hours_Text__c = '2:00';
            listTsi.add(tsi);
            if(mapTimesheetIdToListValues.containskey(tsi.Timesheet__r.Id)) {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                mapTimesheetIdToListValues.get(tsi.Timesheet__r.Id).add(val);
            }
            else {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                List<TimesheetComponentController.DataIdValue> lst = new List<TimesheetComponentController.DataIdValue>();
                lst.add(val);
                mapTimesheetIdToListValues.put(tsi.Timesheet__r.Id, lst);
            }
        }
        update listTsi;
        List<TimesheetComponentController.TimesheetItem> listItem = new List<TimesheetComponentController.TimesheetItem>();
        for(Id tsId :mapTimesheetIdToListValues.keyset()) {
            TimesheetComponentController.TimesheetItem item = new TimesheetComponentController.TimesheetItem();
            item.timesheetId = tsId;
            item.day1=mapTimesheetIdToListValues.get(tsId)[0];
            item.day2=mapTimesheetIdToListValues.get(tsId)[1];
            item.day3=mapTimesheetIdToListValues.get(tsId)[2];
            item.day4=mapTimesheetIdToListValues.get(tsId)[3];
            item.day5=mapTimesheetIdToListValues.get(tsId)[4];
            item.day6=mapTimesheetIdToListValues.get(tsId)[5];
            item.day7=mapTimesheetIdToListValues.get(tsId)[6];
            listItem.add(item);
        }
        string strJson = JSON.serialize(listItem);
        Test.startTest();
        boolean errorThrown = false;
        try {
            TimesheetComponentController.submitProjectTimeSheetData(strJson);
        } catch (Exception e) { errorThrown = true; }
        System.debug('TEST - Error Thrown:'+errorThrown);
        List<Timesheet__c> listTsCheck = [select Id, Name, Employee_Submitted__c, Employee_Submitted_Date__c, Total_Minutes__c
                                  			from Timesheet__c];
        for(Timesheet__c ts :listTsCheck) { System.debug('TEST  - Timesheet Check:'+ts); }
        System.assertEquals(true, errorThrown, 'An error of to few hours should have been thrown');
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitTimesheetsOnePreviouslySubmitted() {
        //submitProjectTimeSheetData
        insertSecondProject();
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        List<Project__c> listPrj = [select Id, Name from Project__c];
        List<Timesheet__c> listTs = new List<Timesheet__c>();
        for(Project_Member__c pmb :[select Id, Name, Member__c, Project__c, Project__r.Id from Project_Member__c where Project__c in :listPrj]) {
            Timesheet__c ts = new Timesheet__c();
            ts.Project__c=pmb.Project__r.Id;
            ts.Member__c=pmb.Member__c;
            ts.Date_Week_Start__c=dt;
            listTs.add(ts);
        }
        listTs[0].Employee_Submitted__c=true;
        listTs[0].Employee_Submitted_Date__c=dt.addDays(-2);
        for(Timesheet__c t :listTs) { System.debug('TEST testSubmitTimesheetsOnePreviouslySubmitted - Timesheet__c:'+t); }
        insert(listTs);
        integer i = 0;
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        Map<Id, List<TimesheetComponentController.DataIdValue>> mapTimesheetIdToListValues = new Map<Id, List<TimesheetComponentController.DataIdValue>>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c, Timesheet__c, Timesheet__r.Id from Timesheet_Item__c where Timesheet__c in :listTs]) {
            //tsi.Hours_Text__c = '3:00';
            tsi.Hours_Text__c = ''+i+':00';
            i=i+1;
            System.debug('tsiItem: '+tsi);
            listTsi.add(tsi);
            if(mapTimesheetIdToListValues.containskey(tsi.Timesheet__r.Id)) {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                mapTimesheetIdToListValues.get(tsi.Timesheet__r.Id).add(val);
            }
            else {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                List<TimesheetComponentController.DataIdValue> lst = new List<TimesheetComponentController.DataIdValue>();
                lst.add(val);
                mapTimesheetIdToListValues.put(tsi.Timesheet__r.Id, lst);
            }
        }
        update listTsi;
        List<TimesheetComponentController.TimesheetItem> listItem = new List<TimesheetComponentController.TimesheetItem>();
        for(Id tsId :mapTimesheetIdToListValues.keyset()) {
            TimesheetComponentController.TimesheetItem item = new TimesheetComponentController.TimesheetItem();
            item.timesheetId = tsId;
            item.day1=mapTimesheetIdToListValues.get(tsId)[0];
            item.day2=mapTimesheetIdToListValues.get(tsId)[1];
            item.day3=mapTimesheetIdToListValues.get(tsId)[2];
            item.day4=mapTimesheetIdToListValues.get(tsId)[3];
            item.day5=mapTimesheetIdToListValues.get(tsId)[4];
            item.day6=mapTimesheetIdToListValues.get(tsId)[5];
            item.day7=mapTimesheetIdToListValues.get(tsId)[6];
            //change one value to test the update works properly
            item.day1.dataValue = '4:30';
            listItem.add(item);
            system.debug('Test: added item:'+item);
        }
        string strJson = JSON.serialize(listItem);
        Test.startTest();
        TimesheetComponentController.submitProjectTimeSheetData(strJson);
        List<Timesheet__c> listTsCheck = [select Id, Name, Employee_Submitted__c, Employee_Submitted_Date__c, Total_Minutes__c
                                  			from Timesheet__c where Employee_Submitted__c=true];
        for(Timesheet__c ts :listTsCheck) { System.debug('TEST  - Timesheet Check:'+ts); }
        System.assertEquals(2, listTsCheck.size(), 'Timesheets submitted should be 2');
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitTimesheetsOneAlreadySubmitted() {
        //submitProjectTimeSheetData
        insertSecondProject();
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        List<Project__c> listPrj = [select Id, Name from Project__c];
        List<Timesheet__c> listTs = new List<Timesheet__c>();
        for(Project_Member__c pmb :[select Id, Name, Member__c, Project__c, Project__r.Id from Project_Member__c where Project__c in :listPrj]) {
            Timesheet__c ts = new Timesheet__c();
            ts.Project__c=pmb.Project__r.Id;
            ts.Member__c=pmb.Member__c;
            ts.Date_Week_Start__c=dt;
            listTs.add(ts);
        }
        for(Timesheet__c ts1 :listTs) {
            ts1.Employee_Submitted__c=true;
        	ts1.Employee_Submitted_Date__c=dt.addDays(-2);
        }
        for(Timesheet__c t :listTs) { System.debug('TEST testSubmitTimesheetsOneAlreadySubmitted - Timesheet__c:'+t); }
        insert(listTs);
        integer i = 0;
        List<Timesheet_Item__c> listTsi = new List<Timesheet_Item__c>();
        Map<Id, List<TimesheetComponentController.DataIdValue>> mapTimesheetIdToListValues = new Map<Id, List<TimesheetComponentController.DataIdValue>>();
        for(Timesheet_Item__c tsi :[select Id, Name, Hours_Text__c, Timesheet__c, Timesheet__r.Id from Timesheet_Item__c where Timesheet__c in :listTs]) {
            //tsi.Hours_Text__c = '3:00';
            tsi.Hours_Text__c = ''+i+':00';
            i=i+1;
            System.debug('tsiItem: '+tsi);
            listTsi.add(tsi);
            if(mapTimesheetIdToListValues.containskey(tsi.Timesheet__r.Id)) {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                mapTimesheetIdToListValues.get(tsi.Timesheet__r.Id).add(val);
            }
            else {
                TimesheetComponentController.DataIdValue val = new TimesheetComponentController.DataIdValue();
            	val.idValue = tsi.Id;
                val.dataValue = tsi.Hours_Text__c;
                List<TimesheetComponentController.DataIdValue> lst = new List<TimesheetComponentController.DataIdValue>();
                lst.add(val);
                mapTimesheetIdToListValues.put(tsi.Timesheet__r.Id, lst);
            }
        }
        update listTsi;
        List<TimesheetComponentController.TimesheetItem> listItem = new List<TimesheetComponentController.TimesheetItem>();
        for(Id tsId :mapTimesheetIdToListValues.keyset()) {
            TimesheetComponentController.TimesheetItem item = new TimesheetComponentController.TimesheetItem();
            item.timesheetId = tsId;
            item.day1=mapTimesheetIdToListValues.get(tsId)[0];
            item.day2=mapTimesheetIdToListValues.get(tsId)[1];
            item.day3=mapTimesheetIdToListValues.get(tsId)[2];
            item.day4=mapTimesheetIdToListValues.get(tsId)[3];
            item.day5=mapTimesheetIdToListValues.get(tsId)[4];
            item.day6=mapTimesheetIdToListValues.get(tsId)[5];
            item.day7=mapTimesheetIdToListValues.get(tsId)[6];
            //change one value to test the update works properly
            item.day1.dataValue = '4:30';
            listItem.add(item);
            system.debug('Test: added item:'+item);
        }
        string strJson = JSON.serialize(listItem);
        Test.startTest();
        boolean errorThrown = false;
        try {
            TimesheetComponentController.submitProjectTimeSheetData(strJson);
        } catch (Exception e) { errorThrown = true; }
        System.debug('TEST - Error Thrown:'+errorThrown);
        List<Timesheet__c> listTsCheck = [select Id, Name, Employee_Submitted__c, Employee_Submitted_Date__c, Total_Minutes__c
                                  			from Timesheet__c];
        for(Timesheet__c ts :listTsCheck) { System.debug('TEST  - Timesheet Check:'+ts); }
        System.assertEquals(true, errorThrown, 'An error of to few hours should have been thrown');
        System.assertEquals(2, listTsCheck.size(), 'Timesheets submitted should be 2');
        Test.stopTest();
    }
	
    @isTest
    static void testDeleteTimesheet(){
        Project__c prj = TestDataFactory.createProject('Test Project');
        insert prj;
        Project_Member__c prjm = TestDataFactory.createProjectMember(prj);
        insert prjm;
        Timesheet__c ts = TestDataFactory.createTimesheet(prjm);
        ts.Date_Week_Start__c = TestDataFactory.getWeekStartDate(-1);
        insert ts;
        System.debug('Test_TimeSheetComponentController.testDeleteTimesheet timesheet:'+ts);
        String sId = String.valueOf(ts.Id);
        TimesheetComponentController.deleteTimesheet(sId);
        AggregateResult aggRes = [select count(Id)recCount from Timesheet__c where Id=:sId];
        System.debug('Test_TimeSheetComponentController.testDeleteTimesheet aggRes:'+aggRes);
        System.assertEquals(aggRes.get('recCount'), 0, 'Seven timesheet items are expected to be created from TimesheetTrigger');
    }
    
    @isTest
    static void testFetchCurrentUserProjectList() {
        List<Project__c> listProj = [select Id, Name, Status__c from Project__c];
        //listProj.add(TestDataFactory.createProject('Test Project'));
        listProj.add(TestDataFactory.createProject('Test Project 2'));
        listProj.add(TestDataFactory.createProject('Test Project 3'));
        upsert listProj;
        System.debug('TEST listProj:'+listProj);
        List<Project_Member__c> listPm = [select Id, Name, Project__c, Member__c, Favorite__c from Project_Member__c];
        //listPm.add(TestDataFactory.createProjectMember(listProj[0]));
        listPm.add(TestDataFactory.createProjectMember(listProj[1]));
        listPm.add(TestDataFactory.createProjectMember(listProj[2]));
        upsert listPm;

        String strJson = TimeSheetComponentController.fetchCurrentUserProjectList(userinfo.getUserId());
        //List<TimeSheetComponentController.ProjectItem>
        List<TimeSheetComponentController.ProjectItem> listPi = (List<TimeSheetComponentController.ProjectItem>) JSON.deserializeStrict(strJson, List<TimeSheetComponentController.ProjectItem>.class);
		System.debug('TEST testFetchCurrentUserProjectList strJson:'+strJson);
        for(TimeSheetComponentController.ProjectItem pi :listPi) { System.debug('TEST testFetchCurrentUserProjectList pi:'+pi); }
        System.assertEquals(listPi.size(), 3, 'Expected 3 items in testFetchCurrentUserProjectList test');
    }
	
    
	@isTest
    static void createDataTestingInsertMultiAfterwards(){
        List<Project__c> listProj = [select Id, Name, Status__c from Project__c];
        //listProj.add(TestDataFactory.createProject('Test Project'));
        listProj.add(TestDataFactory.createProject('Test Project 2'));
        listProj.add(TestDataFactory.createProject('Test Project 3'));
        upsert listProj;
        System.debug('TEST listProj:'+listProj);
        List<Project_Member__c> listPm = [select Id, Name, Project__c, Member__c, Favorite__c from Project_Member__c];
        //listPm.add(TestDataFactory.createProjectMember(listProj[0]));
        listPm.add(TestDataFactory.createProjectMember(listProj[1]));
        listPm.add(TestDataFactory.createProjectMember(listProj[2]));
        upsert listPm;
        System.debug('TEST listPm:'+listPm);
        List<Timesheet__c> listTs = new  List<Timesheet__c>();
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        listTs.add(TestDataFactory.createTimesheet(listPm[1]));
        insert listTs;
        for(Timesheet__c ts :listTs) {
            System.debug('TEST createDataTestingInsertMultiAfterwards BEFORE ts:'+ts);
        }
        
        //TimeSheetComponentController.insertMissingFavoriteTimesheets(listFavPm);
        String sResult = TimeSheetComponentController.setProjectFavorite(String.valueOf(listPm[0].Id), true);
        Project_Member__c pmFav = [select Id, Favorite__c from Project_Member__c where Id=:listPm[0].Id];
        listTs = [select Id, Name, Project__c, Member__c, Date_Week_Start__c from Timesheet__c];
        for(Timesheet__c ts :listTs) {
            System.debug('TEST createDataTestingInsertMultiAfterwards AFTER ts:'+ts);
        }
        System.debug('TEST createDataTestingInsertMultiAfterwards sResult:'+sResult);
        System.assertEquals(sResult, 'Success', 'TimeSheetComponentController.setProjectFavorite expected  result of Success');
        System.assertEquals(pmFav.Favorite__c, true, 'TimeSheetComponentController.setProjectFavorite expected pmFav.Favorite__c to be true');
        
        sResult = TimeSheetComponentController.setProjectFavorite('ABC', true);
        System.debug('TEST createDataTestingInsertMultiAfterwards non-existant Project_Member call sResult:'+sResult);
        System.assertEquals(sResult, 'Project not found', 'TimeSheetComponentController.setProjectFavorite expected  result of Success');
        
        sResult = TimeSheetComponentController.setProjectFavorite(String.valueOf(listPm[0].Id), false);
        pmFav = [select Id, Favorite__c from Project_Member__c where Id=:listPm[0].Id];
        System.assertEquals(sResult, 'Success', 'TimeSheetComponentController.setProjectFavorite expected  result of Success');
        System.assertEquals(pmFav.Favorite__c, false, 'TimeSheetComponentController.setProjectFavorite expected pmFav.Favorite__c to be false');
        
    }
}