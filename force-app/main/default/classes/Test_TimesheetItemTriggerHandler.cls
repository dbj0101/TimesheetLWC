@isTest(seeAllData = false)
public class Test_TimesheetItemTriggerHandler {
	@TestSetup
    static void createTestData(){
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';
        prj.Status__c='Not Started';
        insert prj;

        Project_Member__c prjm = new Project_Member__c();
        prjm.Member__c = userinfo.getUserId();
        prjm.Project__c = prj.Id;
        insert prjm;

        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=prj.Id;
        ts.Member__c=prjm.Member__c;
        ts.Date_Week_Start__c=dt;
        insert ts;
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

        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=prj.Id;
        ts.Member__c=prjm.Member__c;
        ts.Date_Week_Start__c=dt;
        insert ts;
    }
    
    @isTest
    static void TestDuplicateInsert() {
        Timesheet__c ts = [select Id, Name from Timesheet__c limit 1];
        System.debug('TEST_TimesheetItemTriggerHandler.TestDuplicateInsert - ts:'+ts);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:ts.Id];
        List<Timesheet_Item__c> listInsert = new List<Timesheet_Item__c>();
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi[3].Hours_Text__c;
        ti.Timesheet__c=listTsi[3].Timesheet__c;
        listInsert.add(ti);
        System.debug('TEST_TimesheetItemTriggerHandler.TestDuplicateInsert - listInsert:'+listInsert);
        Database.SaveResult[] listSr = Database.insert(listInsert, false);
        System.debug('TEST_TimesheetItemTriggerHandler.TestDuplicateInsert - SaveResult[0]'+listSr[0]);
        System.assertEquals(false, listSr[0].isSuccess(), 'TEST_TimesheetItemTriggerHandler.TestDuplicateInsert allowed a duplicate item');
    }
    
    @isTest
    static void TestTwoLegitInsert() {
        Timesheet__c ts = [select Id, Name from Timesheet__c limit 1];
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoLegitInsert - ts:'+ts);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:ts.Id];
        List<Timesheet_Item__c> listInsert = new List<Timesheet_Item__c>();
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi[3].Hours_Text__c;
        ti.Timesheet__c=listTsi[3].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTsi[4].Timesheet__c;
        listInsert.add(ti);
        delete listTsi[4];
        delete listTsi[3];
        
        Test.startTest();
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoLegitInsert - listInsert:'+listInsert);
        Database.SaveResult[] listSr = Database.insert(listInsert, false);
        integer countSuccess=0, countError=0;
        for(Database.SaveResult sr :listSr) {
            if(sr.isSuccess()) {
                countSuccess=countSuccess+1;
            }
            else {
                countError=countError+1;
            }
            System.debug('TEST_TimesheetItemTriggerHandler.TestTwoLegitInsert - SaveResult:'+sr);
        }
        System.assertEquals(2, countSuccess, 'TEST_TimesheetItemTriggerHandler.TestTwoLegitInsert did not have enough successes');
        System.assertEquals(0, countError, 'TEST_TimesheetItemTriggerHandler.TestTwoLegitInsert had too many Errors');
        Test.stopTest();
    }
    
    @isTest
    static void TestOneLegitOneErrorInsert() {
        Timesheet__c ts = [select Id, Name from Timesheet__c limit 1];
        System.debug('TEST_TimesheetItemTriggerHandler.TestOneLegitOneErrorInsert - ts:'+ts);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:ts.Id];
        List<Timesheet_Item__c> listInsert = new List<Timesheet_Item__c>();
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi[3].Hours_Text__c;
        ti.Timesheet__c=listTsi[3].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTsi[4].Timesheet__c;
        listInsert.add(ti);
        delete listTsi[4];
        
        Test.startTest();
        System.debug('TEST_TimesheetItemTriggerHandler.TestOneLegitOneErrorInsert - listInsert:'+listInsert);
        Database.SaveResult[] listSr = Database.insert(listInsert, false);
        integer countSuccess=0, countError=0;
        for(Database.SaveResult sr :listSr) {
            if(sr.isSuccess()) {
                countSuccess=countSuccess+1;
            }
            else {
                countError=countError+1;
            }
            System.debug('TEST_TimesheetItemTriggerHandler.TestOneLegitOneErrorInsert - SaveResult:'+sr);
        }
        System.assertEquals( 1, countSuccess,'TEST_TimesheetItemTriggerHandler.TestOneLegitOneErrorInsert did not have enough successes');
        System.assertEquals(1, countError, 'TEST_TimesheetItemTriggerHandler.TestOneLegitOneErrorInsert had too many Errors');
        Test.stopTest();
    }
    
    @isTest
    static void TestTwoProjectsOneLegitOneErrorInsert() {
        insertSecondProject();
        List<Timesheet__c> listTs = [select Id, Name, Project__c from Timesheet__c];
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsOneLegitOneErrorInsert - listTs:'+listTs);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:listTs[0].Id];
        List<Timesheet_Item__c> listInsert = new List<Timesheet_Item__c>();
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTsi[4].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTs[1].Id;
        listInsert.add(ti);
        delete listTsi[4];
        
        Test.startTest();
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsOneLegitOneErrorInsert - listInsert:'+listInsert);
        Database.SaveResult[] listSr = Database.insert(listInsert, false);
        integer countSuccess=0, countError=0;
        for(Database.SaveResult sr :listSr) {
            if(sr.isSuccess()) {
                countSuccess=countSuccess+1;
            }
            else {
                countError=countError+1;
            }
            System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsOneLegitOneErrorInsert - SaveResult:'+sr);
        }
        System.assertEquals( 1, countSuccess,'TEST_TimesheetItemTriggerHandler.TestTwoProjectsOneLegitOneErrorInsert did not have enough successes');
        System.assertEquals(1, countError, 'TEST_TimesheetItemTriggerHandler.TestTwoProjectsOneLegitOneErrorInsert had too many Errors');
        Test.stopTest();
    }
    
    @isTest
    static void TestTwoProjectsEachHavingOneLegitOneErrorInsert() {
        insertSecondProject();
        List<Timesheet__c> listTs = [select Id, Name, Project__c from Timesheet__c];
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorInsert - listTs:'+listTs);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:listTs[0].Id];
        List<Timesheet_Item__c> listTsi2nd = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:listTs[1].Id];
        List<Timesheet_Item__c> listInsert = new List<Timesheet_Item__c>();
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi[3].Hours_Text__c;
        ti.Timesheet__c=listTsi[3].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTsi[4].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi2nd[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi2nd[3].Hours_Text__c;
        ti.Timesheet__c=listTsi2nd[3].Timesheet__c;
        listInsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi2nd[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi2nd[4].Hours_Text__c;
        ti.Timesheet__c=listTsi2nd[4].Timesheet__c;
        listInsert.add(ti);
        delete listTsi[4];
        delete listTsi2nd[3];
        
        Test.startTest();
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorInsert - listInsert:'+listInsert);
        Database.SaveResult[] listSr = Database.insert(listInsert, false);
        integer countSuccess=0, countError=0;
        for(Database.SaveResult sr :listSr) {
            if(sr.isSuccess()) {
                countSuccess=countSuccess+1;
            }
            else {
                countError=countError+1;
            }
            System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorInsert - SaveResult:'+sr);
        }
        System.assertEquals(2, countSuccess,'TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorInsert did not have enough successes');
        System.assertEquals(2, countError, 'TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorInsert had too many Errors');
        Test.stopTest();
    }
    
    @isTest
    static void TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert() {
        insertSecondProject();
        List<Timesheet__c> listTs = [select Id, Name, Project__c from Timesheet__c];
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert - listTs:'+listTs);
        List<Timesheet_Item__c> listTsi = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:listTs[0].Id];
        List<Timesheet_Item__c> listTsi2nd = [select Id, Name, Logged_Date__c, Hours_Text__c, Timesheet__c from Timesheet_Item__c where Timesheet__c=:listTs[1].Id];
        List<Timesheet_Item__c> listUpsert = new List<Timesheet_Item__c>();
        
        //Add the Inserts
        Timesheet_Item__c ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi[3].Hours_Text__c;
        ti.Timesheet__c=listTsi[3].Timesheet__c;
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi[4].Hours_Text__c;
        ti.Timesheet__c=listTsi[4].Timesheet__c;
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi2nd[3].Logged_Date__c;
        ti.Hours_Text__c=listTsi2nd[3].Hours_Text__c;
        ti.Timesheet__c=listTsi2nd[3].Timesheet__c;
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Logged_Date__c=listTsi2nd[4].Logged_Date__c;
        ti.Hours_Text__c=listTsi2nd[4].Hours_Text__c;
        ti.Timesheet__c=listTsi2nd[4].Timesheet__c;
        listUpsert.add(ti);
        
        //Add the Updates
        //Should fail when trying to change Logged_Date__c
        ti = new Timesheet_Item__c();
        ti.Id=listTsi[5].Id;
        ti.Logged_Date__c=listTsi[6].Logged_Date__c;
        ti.Hours_Text__c='2:00';
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Id=listTsi[6].Id;
        ti.Hours_Text__c='4:00';
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Id=listTsi2nd[5].Id;
        ti.Hours_Text__c='5:00';
        listUpsert.add(ti);
        ti = new Timesheet_Item__c();
        ti.Id=listTsi2nd[6].Id;
        ti.Logged_Date__c=listTsi2nd[5].Logged_Date__c;
        ti.Hours_Text__c='7:00';
        listUpsert.add(ti);
        
        //Remove one Insert of each
        delete listTsi[4];
        delete listTsi2nd[3];
        
        Test.startTest();
        System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert - listUpsert:'+listUpsert);
        List<Database.UpsertResult> listUr = Database.upsert(listUpsert, false);
        integer countSuccess=0, countError=0;
        for(Database.UpsertResult ur :listUr) {
            if(ur.isSuccess()) {
                countSuccess=countSuccess+1;
            }
            else {
                countError=countError+1;
            }
            System.debug('TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert - UpsertResult:'+ur);
        }
        System.assertEquals(4, countSuccess,'TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert did not have enough successes');
        System.assertEquals(4, countError, 'TEST_TimesheetItemTriggerHandler.TestTwoProjectsEachHavingOneLegitOneErrorUpdateAndInsert had too many Errors');
        Test.stopTest();
    }
}