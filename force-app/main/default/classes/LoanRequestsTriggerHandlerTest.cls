@IsTest
public class LoanRequestsTriggerHandlerTest {

    // --- Mock של LoanRequestService כדי למנוע קריאות חיצוניות ---
    // אם יש לך LoanRequestService אמיתי, המחלקה הזאת מוודאת שלא נשלחים מיילים או Tasks בזמן Unit Test
    public class LoanRequestServiceMock {
        public static void createHighAmountTasks(List<LoanRequest__c> lrList) { /* do nothing */ }
        public static void sendApprovalEmails(List<LoanRequest__c> newList, Map<Id, LoanRequest__c> oldMap) { /* do nothing */ }
    }

    // --- יצירת לקוח לדוגמה ---
    private static Customer__c createTestCustomer(String suffix) {
        Customer__c c = new Customer__c(
            Name = 'Test Customer ' + suffix,
            Status__c = 'New',
            Email__c = 'test' + suffix + '@example.com'
        );
        insert c;
        return c;
    }

    @IsTest
    static void testAfterInsert_AuditCreated() {
        Customer__c cust = createTestCustomer('Insert1');

        LoanRequest__c lr = new LoanRequest__c(
            Customer__c = cust.Id,
            LoanAmount__c = 100000,
            LoanStatus__c = 'Draft'
        );

        Test.startTest();
        insert lr;
        Test.stopTest();

        List<Audit__c> audits = [SELECT Id, Customer__c, Loan_Request__c, Action__c
                                FROM Audit__c 
                                WHERE Loan_Request__c = :lr.Id];

        System.assertEquals(1, audits.size(), 'Audit record should be created');
        System.assertEquals('Created', audits[0].Action__c);
        System.assertEquals(cust.Id, audits[0].Customer__c);
    }

    @IsTest
    static void testAfterUpdate_AuditStatusChanged() {
        Customer__c cust = createTestCustomer('Update1');

        LoanRequest__c lr = new LoanRequest__c(
            Customer__c = cust.Id,
            LoanAmount__c = 150000,
            LoanStatus__c = 'Draft'
        );
        insert lr;

        lr.LoanStatus__c = 'Approved';

        Test.startTest();
        update lr;
        Test.stopTest();

        List<Audit__c> audits = [SELECT Id, Customer__c, Loan_Request__c, Loan_Status__c, Action__c
                                 FROM Audit__c 
                                 WHERE Loan_Request__c = :lr.Id AND Action__c = 'Status Changed'];

        System.assertEquals(1, audits.size(), 'Audit record should be created for status change');
        System.assertEquals('Approved', audits[0].Loan_Status__c);
        System.assertEquals(cust.Id, audits[0].Customer__c);
    }

    @IsTest
    static void testBulkInsertAndUpdate() {
        List<Customer__c> customers = new List<Customer__c>();
        for(Integer i=0; i<5; i++){
            customers.add(createTestCustomer('Bulk' + i));
        }

        List<LoanRequest__c> loans = new List<LoanRequest__c>();
        for(Customer__c c : customers){
            loans.add(new LoanRequest__c(
                Customer__c = c.Id,
                LoanAmount__c = 200000,
                LoanStatus__c = 'Draft'
            ));
        }

        Test.startTest();
        insert loans;

        for(LoanRequest__c lr : loans){
            lr.LoanStatus__c = 'Approved';
        }
        update loans;
        Test.stopTest();

        List<Audit__c> audits = [SELECT Id, Loan_Request__c, Action__c 
                                 FROM Audit__c 
                                 WHERE Loan_Request__c IN :loans];

        System.assertEquals(loans.size() * 2, audits.size(), 'Each LoanRequest should have 2 audits: Created + Status Changed');
    }
}
