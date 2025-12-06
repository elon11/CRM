@IsTest
public class LoanRequestsTriggerHandlerTest {

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
    }

    @IsTest
    static void testBeforeInsert() {
        List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 2];

        List<LoanRequest__c> loans = new List<LoanRequest__c>();
        loans.add(new LoanRequest__c(
            Customer__c = customers[0].Id,
            LoanAmount__c = 100000
            // LoanStatus__c and RequestDate__c are blank intentionally
        ));

        Test.startTest();
        LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();
        handler.beforeInsert(loans);
        Test.stopTest();

        System.assertEquals('Draft', loans[0].LoanStatus__c, 'Default LoanStatus__c should be Draft');
        System.assertEquals(Date.today(), loans[0].RequestDate__c, 'RequestDate__c should be set to today');
    }

    @IsTest
    static void testBeforeUpdate() {
        List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 2];
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customers[0].Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Approved',
            RequestDate__c = Date.today()
        );
        insert loan;

        // Simulate update trying to regress status to Draft
        LoanRequest__c updatedLoan = new LoanRequest__c(
            Id = loan.Id,
            LoanStatus__c = 'Draft'
        );

        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>{ loan.Id => loan };
        List<LoanRequest__c> newRecords = new List<LoanRequest__c>{ updatedLoan };

        Test.startTest();
        LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();
        handler.beforeUpdate(newRecords, oldMap);
        Test.stopTest();

        System.assertEquals('Approved', newRecords[0].LoanStatus__c, 'Status regression should be prevented');
    }

    @IsTest
    static void testAfterInsert() {
        List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 2];
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customers[0].Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft',
            RequestDate__c = Date.today()
        );

        Test.startTest();
        LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();
        handler.afterInsert(new List<LoanRequest__c>{ loan });
        Test.stopTest();

        List<Audit__c> audits = [SELECT Id, Action__c FROM Audit__c WHERE Loan_Request__c = :loan.Id];
        System.assertEquals(1, audits.size(), 'One audit record should be created after insert');
        System.assertEquals('Created', audits[0].Action__c);
    }

    @IsTest
    static void testAfterUpdate() {
        List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 2];
        LoanRequest__c loan = new LoanRequest__c(
            Customer__c = customers[0].Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft',
            RequestDate__c = Date.today()
        );
        insert loan;

        LoanRequest__c updatedLoan = new LoanRequest__c(
            Id = loan.Id,
            LoanStatus__c = 'Approved'
        );

        Map<Id, LoanRequest__c> oldMap = new Map<Id, LoanRequest__c>{ loan.Id => loan };
        List<LoanRequest__c> newRecords = new List<LoanRequest__c>{ updatedLoan };

        Test.startTest();
        LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();
        handler.afterUpdate(newRecords, oldMap);
        Test.stopTest();

        List<Audit__c> audits = [SELECT Id, Action__c, Description__c FROM Audit__c WHERE Loan_Request__c = :loan.Id AND Action__c = 'Status Changed'];
        System.assertEquals(1, audits.size(), 'One audit record should be created for status change');
        System.assert(audits[0].Description__c.contains('Draft') && audits[0].Description__c.contains('Approved'), 'Audit description should reflect status change');
    }
}
