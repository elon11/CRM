@isTest
public class LoanRequestsTriggerHandlerTest {

    private static Customer__c createCustomer() {
        Customer__c c = new Customer__c(
            Name = 'Test Customer',
            Email__c = 'customer@example.com',
            Status__c = 'New'
        );
        insert c;
        return c;
    }

    private static LoanRequest__c createLoanRequest(Id customerId) {
        LoanRequest__c lr = new LoanRequest__c(
            Customer__c = customerId,
            LoanAmount__c = 50000,
            LoanStatus__c = 'Draft'
        );
        insert lr;
        return lr;
    }

    @isTest
    static void testAfterInsertCreatesAudit() {
        Customer__c c = createCustomer();

        Test.startTest();
        LoanRequest__c lr = new LoanRequest__c(
            Customer__c = c.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft'
        );
        insert lr;
        Test.stopTest();

        List<Audit__c> audits = [
            SELECT Id, Customer_custom__c, Loan_Request__c, Loan_Amount__c,
                   Loan_Status__c, Action__c, Description__c
            FROM Audit__c
            WHERE Loan_Request__c = :lr.Id
        ];

        System.assertEquals(1, audits.size(), 'Audit should be created after insert.');
        Audit__c a = audits[0];
        System.assertEquals(c.Id, a.Customer_custom__c, 'Customer ID must match.');
        System.assertEquals(100000, a.Loan_Amount__c);
        System.assertEquals('Draft', a.Loan_Status__c);
        System.assertEquals('Created', a.Action__c);
        System.assertEquals('Loan request created.', a.Description__c);
    }

    @isTest
    static void testAfterUpdateCreatesAuditOnStatusChange() {
        Customer__c c = createCustomer();
        LoanRequest__c lr = createLoanRequest(c.Id);

        Test.startTest();
        lr.LoanStatus__c = 'Approved';
        update lr;
        Test.stopTest();

        List<Audit__c> audits = [
            SELECT Id, Action__c, Description__c, Loan_Status__c
            FROM Audit__c
            WHERE Loan_Request__c = :lr.Id
              AND Action__c = 'Status Changed'
        ];

        System.assertEquals(1, audits.size(), 'Audit should be created for status change.');
        System.assertEquals('Approved', audits[0].Loan_Status__c);
        System.assert(
            audits[0].Description__c.contains('Draft') &&
            audits[0].Description__c.contains('Approved'),
            'Description must contain old and new statuses.'
        );
    }

    @isTest
    static void testLoanRequestWithNegativeAmount() {
        Customer__c c = createCustomer();

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LoanRequest__c lr = new LoanRequest__c(
                Customer__c = c.Id,
                LoanAmount__c = -1000,
                LoanStatus__c = 'Draft'
            );
            insert lr;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Loan Amount must be positive'),
                'Expected validation error for negative loan amount.'
            );
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Insert should fail due to invalid loan amount.');

        // וודא שלא נוצרו רשומות Audit
        List<Audit__c> audits = [
            SELECT Id FROM Audit__c
            WHERE Loan_Request__c IN (SELECT Id FROM LoanRequest__c WHERE LoanAmount__c = -1000)
        ];
        System.assertEquals(0, audits.size(), 'Audit should not be created for invalid loan amount.');
    }
}
