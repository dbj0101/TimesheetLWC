@isTest(seeAllData = false)
public with sharing class Test_TimesheetTrigger {
	
    @isTest
    static void createDataTestingTimesheetTrigger(){
        Project__c prj = TestDataFactory.createProject('Test Project');
        insert prj;
        Project_Member__c prjm = TestDataFactory.createProjectMember(prj);
        insert prjm;
        Timesheet__c ts = TestDataFactory.createTimesheet(prjm);
        ts.Date_Week_Start__c = TestDataFactory.getWeekStartDate(-1);
        insert ts;
        System.debug('Test_TimesheetTrigger.createDataTestingTimesheetTrigger project:'+prj);
        List<Timesheet_Item__c> listTsi = [select Id, Name from Timesheet_Item__c where Timesheet__c=:ts.Id];
        System.assertEquals(listTsi.size(), 7, 'Seven timesheet items are expected to be created from TimesheetTrigger');
    }
    
	@isTest
    static void createDataTestingInsertMultiInitially(){
        List<Project__c> listProj = new List<Project__c>();
        listProj.add(TestDataFactory.createProject('Test Project'));
        listProj.add(TestDataFactory.createProject('Test Project 2'));
        listProj.add(TestDataFactory.createProject('Test Project 3'));
        insert listProj;
        List<Project_Member__c> listPm = new List<Project_Member__c>();
        listPm.add(TestDataFactory.createProjectMember(listProj[0]));
        listPm.add(TestDataFactory.createProjectMember(listProj[1]));
        listPm.add(TestDataFactory.createProjectMember(listProj[2]));
        insert listPm;
        List<Timesheet__c> listTs = new  List<Timesheet__c>();
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        listTs.add(TestDataFactory.createTimesheet(listPm[1]));
        listTs.add(TestDataFactory.createTimesheet(listPm[2]));
        for(Timesheet__c ts :listTs)  { System.debug('TEST ts:'+ts); }
        Database.SaveResult[] listSr = Database.insert(listTs,  false);
        integer iSuccess=0;
        integer iError=0;
        for(Database.SaveResult sr :listSr) { 
            System.debug('SaveResult:'+sr); 
            if(sr.isSuccess()) {
                iSuccess=iSuccess+1;
            }
            else {
                iError=iError+1;
            }
        }
        System.debug('Test_TimesheetTrigger.createDataTestingInsertMultiInitially iSuccess:'+iSuccess+' ##  iError:'+iError);
        System.assertEquals(iSuccess, 3, 'Three timesheet items are expected to be created from TimesheetTrigger.createDataTestingInsertMultiInitially');
        System.assertEquals(iError, 1, 'One timesheet is expected to have an error creating from TimesheetTrigger.createDataTestingInsertMultiInitially');
    }
    
	@isTest
    static void createDataTestingInsertMultiAfterwards(){
        List<Project__c> listProj = new List<Project__c>();
        listProj.add(TestDataFactory.createProject('Test Project'));
        listProj.add(TestDataFactory.createProject('Test Project 2'));
        listProj.add(TestDataFactory.createProject('Test Project 3'));
        insert listProj;
        List<Project_Member__c> listPm = new List<Project_Member__c>();
        listPm.add(TestDataFactory.createProjectMember(listProj[0]));
        listPm.add(TestDataFactory.createProjectMember(listProj[1]));
        listPm.add(TestDataFactory.createProjectMember(listProj[2]));
        insert listPm;
        List<Timesheet__c> listTs = new  List<Timesheet__c>();
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        listTs.add(TestDataFactory.createTimesheet(listPm[1]));
        listTs.add(TestDataFactory.createTimesheet(listPm[2]));
        insert listTs;
        listTs=new List<Timesheet__c>();
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        Database.SaveResult[] listSr = Database.insert(listTs,  false);
        integer iSuccess=0;
        integer iError=0;
        for(Database.SaveResult sr :listSr) { 
            System.debug('SaveResult:'+sr); 
            if(sr.isSuccess()) {
                iSuccess=iSuccess+1;
            }
            else {
                iError=iError+1;
            }
        }
        System.debug('Test_TimesheetTrigger.createDataTestingInsertMultiInitially iSuccess:'+iSuccess+' ##  iError:'+iError);
        System.assertEquals(iError, 1, 'One timesheet is expected to have an error creating from TimesheetTrigger.createDataTestingInsertMultiInitially');
    }
    
	@isTest
    static void createDataTestingUpdateMulti(){
        List<Project__c> listProj = new List<Project__c>();
        listProj.add(TestDataFactory.createProject('Test Project'));
        listProj.add(TestDataFactory.createProject('Test Project 2'));
        listProj.add(TestDataFactory.createProject('Test Project 3'));
        insert listProj;
        List<Project_Member__c> listPm = new List<Project_Member__c>();
        listPm.add(TestDataFactory.createProjectMember(listProj[0]));
        listPm.add(TestDataFactory.createProjectMember(listProj[1]));
        listPm.add(TestDataFactory.createProjectMember(listProj[2]));
        insert listPm;
        List<Timesheet__c> listTs = new  List<Timesheet__c>();
        listTs.add(TestDataFactory.createTimesheet(listPm[0]));
        listTs.add(TestDataFactory.createTimesheet(listPm[1]));
        listTs.add(TestDataFactory.createTimesheet(listPm[2]));
        insert listTs;
        List<Timesheet__c> listTsUpdate=new List<Timesheet__c>();
        listTsUpdate.add(listTs[0]);
        listTsUpdate[0].Project__c = listProj[1].Id;
        Database.SaveResult[] listSr = Database.update(listTsUpdate,  false);
        integer iSuccess=0;
        integer iError=0;
        for(Database.SaveResult sr :listSr) { 
            System.debug('SaveResult:'+sr); 
            if(sr.isSuccess()) {
                iSuccess=iSuccess+1;
            }
            else {
                iError=iError+1;
            }
        }
        System.debug('Test_TimesheetTrigger.createDataTestingUpdateMulti iSuccess:'+iSuccess+' ##  iError:'+iError);
        System.assertEquals(iError, 1, 'One timesheet is expected to have an error creating from TimesheetTrigger.createDataTestingUpdateMulti');
    }
}