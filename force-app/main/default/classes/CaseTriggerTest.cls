@isTest
public class CaseTriggerTest {
    @isTest
    static void testCaseTrigger(){
        Case c = new Case(
            Type = 'Mechanical',
            Priority = 'Medium',
            Subject = 'Test Subject',
            Description = 'Test Description'
        );
        
        String userId = UserInfo.getUserId();
        system.debug('userId => ' + userId);
        User u = [SELECT Id, Username, LastName, FirstName, Name FROM User WHERE Id = :userId];
        Test.startTest();
        insert c;
        system.assertEquals(null, c.Nonconformance__c, 'Since type is not problem, Nonconformance should not be created');
        
        c.Type = CaseTriggerHandler.CASE_TYPE;
        update c;
        Case cs = [SELECT Nonconformance__c FROM Case WHERE Id = :c.Id LIMIT 1];
        system.debug('c => ' + c);
        system.assertEquals(false, String.isEmpty(cs.Nonconformance__c), 'since we updated the case type, Nonconformance should be created.');
        Test.stopTest();
        
    }
    
    public static testMethod void testRunAs() {
        // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            Test.startTest();
            Case c = new Case(
                Priority = 'Medium',
                Subject = 'Test Subject',
                Description = 'Test Description',
                Type = CaseTriggerHandler.CASE_TYPE
            );
            
            insert c;
            Test.stopTest();
            system.assertEquals(
                null, 
                c.Nonconformance__c, 
                'since user doesn\'t have Case Admin Permission set assigned, Nonconformance should not be created.' 
            );
        }
    }
    
    
}