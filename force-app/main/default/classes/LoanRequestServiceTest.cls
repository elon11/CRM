@IsTest
public class LoanRequestServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test customers
        List<Customer__c> customers = new List<Customer__c>();
        for (Integer i = 1; i <= 2; i++) {
            customers.add(new Customer__c(
                Name = 'Customer ' + i,
                Email__c = 'customer' + i + '@example.com',
                Phone__c = '05012345' + i
            ));
        }
        insert customers;

        // Create test LoanRequests
        List<LoanRequest__c> loans = new List<LoanRequest__c>();
        loans.add(new LoanRequest__c(
            Customer__c = customers[0].Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft',
            RequestDate__c = Date.today()
        ));
        loans.add(new LoanRequest__c(
            Customer__c = customers[1].Id,
            LoanAmount__c = 300000, // High amount
            LoanStatus__c = 'Draft',
            RequestDate__c = Date.today()
        ));
        insert loans;
    }

    @IsTest
    static void testCreateHighAmountTasks() {
        List<LoanRequest__c> loans = [SELECT Id, LoanAmount__c FROM LoanRequest__c];

        Test.startTest();
        LoanRequestService.createHighAmountTasks(loans);
        Test.stopTest();

        // Verify that Task was created for high amount loan only
        List<Task> tasks = [SELECT Id, Subject, WhatId, Priority FROM Task WHERE WhatId IN :loans];
        System.assertEquals(1, tasks.size(), 'Only one Task should be created for loan > 250,000');
        System.assertEquals('High Loan Amount Approval Needed', tasks[0].Subject);
        System.assertEquals('High', tasks[0].Priority);
    }

    @IsTest
    static void testSendApprovalEmails() {
        List<LoanRequest__c> loans = [SELECT Id, LoanStatus__c, Customer__c FROM LoanRequest__c];
        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>();
        for (LoanRequest__c l : loans) {
            oldMap.put(l.Id, l.clone(false, true, false, false));
        }

        // Update one loan to Approved
        LoanRequest__c toUpdate = loans[1];
        toUpdate.LoanStatus__c = 'Approved';

        Test.startTest();
        update toUpdate; // trigger will call service
        Test.stopTest();

        // Since email sending cannot be queried, we assert by checking limits usage
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been invoked');
    }
}
