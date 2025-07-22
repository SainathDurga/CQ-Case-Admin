public with sharing class CaseTriggerHandler {
    public static String CASE_TYPE = 'Problem';
    public static String PS_NAME = 'Case_Admin';
    
    public static void handleNonconformanceEscalation(List<Case> cases){
        if(cases.isEmpty()){ return; }
        
        List<Case> casesToEscalate = new List<Case>();
        List<Case> newlyCreatedCases = new List<Case>();
        
        if(!hasPermissions()){ return; }   
        
        casesToEscalate = getEscalatedCases(cases);
        if(casesToEscalate.isEmpty()){return;}
        
        for(case c : casesToEscalate){
            if(c.Nonconformance__c != null){continue;}
            newlyCreatedCases.add(c);
        }
        
        if(newlyCreatedCases.isEmpty()){ return; }
        createNonconformance(newlyCreatedCases);
    }
    
    private static Boolean hasPermissions(){
        Boolean hasPermission = false;
        
        List<PermissionSet> allowedPermissionSets = new List<PermissionSet>();
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        
        String userId = UserInfo.getUserId();
        
        allowedPermissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name = :PS_NAME 
                                 WITH USER_MODE LIMIT 1];
        if(allowedPermissionSets.isEmpty()){ return hasPermission; }
        
        psa = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment 
               WHERE PermissionSetId = :allowedPermissionSets[0].Id AND 
               AssigneeId = :userId WITH USER_MODE];
        
        if(psa.isEmpty()){return hasPermission;}
        hasPermission = true;
        return hasPermission;
        
    }
    
    private static List<Case> getEscalatedCases(List<Case> cases){
        List<Case> casesToEscalate = new List<Case>();
        
        for(Case c : cases){
            if(c.Type != CASE_TYPE){continue;}
            casesToEscalate.add(c);
        }
        
        return casesToEscalate;
    }
    
    private static void createNonconformance(List<Case> cases){
        Map<String, Id> caseNumberIdMap = new Map<String, Id>();
        
        List<Case> casesToUpdate = new List<Case>();
        List<SQX_Nonconformance__c> ncList = new List<SQX_Nonconformance__c>();
        
        Set<String> errorCaseIds = new Set<String>();
        
        for(case c : cases){
            caseNumberIdMap.put(c.CaseNumber, c.Id);
            SQX_Nonconformance__c nc = new SQX_Nonconformance__c(
                QMS_Reference_Number__c  = c.CaseNumber,
            	Description__c = c.Description,
                Priority__c = c.Priority,
                Title__c = c.Subject
            );
            ncList.add(nc);
        }
        
        Database.SaveResult[] saveResults = Database.Insert(ncList, false, AccessLevel.USER_MODE);
        
        for(Database.SaveResult saveResult : saveResults){
            if(saveResult.isSuccess()){continue;}
            List<Database.error> errors = new List<Database.error>();
            for(Database.error error : errors){
              	errorCaseIds.add(saveResult.getId() + ' => ' + error.getMessage());  
            }
        }
        
        if(!errorCaseIds.isEmpty()){
            system.debug('Error in CaseTriggerHanlder :: ' + errorCaseIds);
            return;
        }
        
        for(SQX_Nonconformance__c nc : ncList){
            String caseNumber = nc.QMS_Reference_Number__c;
            if(!caseNumberIdMap.containsKey(caseNumber)){continue;}
            
            Case c = new Case(
                Id = caseNumberIdMap.get(caseNumber),
                Nonconformance__c = nc.Id
            );
            casesToUpdate.add(c);
        }
        update as user casesToUpdate;
    }

}