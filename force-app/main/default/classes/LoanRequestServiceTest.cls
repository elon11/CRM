@IsTest
public class LoanRequestServiceTest {

    @TestSetup
    static void setupTestData() {
        Customer__c customer = new Customer__c(
            Name = 'Test Customer',
            Email__c = 'test@example.com',
            Phone__c = '0501234567',
            Status__c = 'New'
        );
        insert customer;
    }

    @IsTest
    static void testHighAmountTaskCreation() {
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        LoanRequest__c highLoan = new LoanRequest__c(
            Customer__c = customer.Id,
            LoanAmount__c = 300000, 
            LoanStatus__c = 'Draft'
        );
        LoanRequest__c lowLoan = new LoanRequest__c(
            Customer__c = customer.Id,
            LoanAmount__c = 200000, 
            LoanStatus__c = 'Draft'
        );

        insert new List<LoanRequest__c>{highLoan, lowLoan};

        Test.startTest();
        LoanRequestService.createHighAmountTasks(new List<LoanRequest__c>{highLoan, lowLoan});
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, WhatId, Status, Priority, Description 
                            FROM Task 
                            WHERE WhatId IN :new List<Id>{highLoan.Id, lowLoan.Id}];

        System.assertEquals(1, tasks.size(), 'Should create exactly 1 task for high loan amount');

        Task createdTask = tasks[0];
        System.assertEquals(highLoan.Id, createdTask.WhatId, 'Task should be linked to the high amount loan');
        System.assertEquals('High Loan Amount Approval Needed', createdTask.Subject, 'Task subject should be correct');
        System.assertEquals('Not Started', createdTask.Status, 'Task status should be correct');
        System.assertEquals('High', createdTask.Priority, 'Task priority should be correct');
        System.assert(createdTask.Description.contains('over 250,000'), 'Task description should mention high amount');
    }

    @IsTest
    static void testSendApprovalEmailToCustomer() {
        Customer__c customer = [SELECT Id, Email__c FROM Customer__c LIMIT 1];

        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customer.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft'
        );
        insert loan;

        LoanRequest__c oldLoan = loan.clone(false, true);
        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>{ loan.Id => oldLoan };

        loan.LoanStatus__c = 'Approved';
        update loan;

        Test.startTest();
        LoanRequestService.sendApprovalEmails(new List<LoanRequest__c>{loan}, oldMap);
        Test.stopTest();

        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been invoked');
    }

    @IsTest
    static void testLoanRequestWithNegativeAmount() {
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LoanRequest__c invalidLoan = new LoanRequest__c(
                Customer__c = customer.Id,
                LoanAmount__c = -5000,
                LoanStatus__c = 'Draft'
            );
            insert invalidLoan;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Loan Amount must be positive'),
                'Expected validation error for negative loan amount.'
            );
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Insert should fail due to invalid loan amount.');
    }
}
