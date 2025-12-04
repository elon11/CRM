/**
 * @Class Name: LoanRequestsTriggerHandler
 * @Description: Contains business logic for LoanRequest__c trigger events.
 *              Ensures clean separation of concerns and support for bulk operations.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-04
 */
public with sharing class LoanRequestsTriggerHandler {

    /**
     * @Method Name: beforeInsert
     * @Input: List<LoanRequest__c> newRecords
     * @Description: Validates new LoanRequest__c records before insertion.
     */
    public void beforeInsert(List<LoanRequest__c> newRecords) {
        for (LoanRequest__c req : newRecords) {
            // Ensure RequestDate__c is populated
            if (req.RequestDate__c == null) {
                req.RequestDate__c = Date.today();
            }

            // Default status
            if (String.isBlank(req.LoanStatus__c)) {
                req.LoanStatus__c = 'Draft';
            }
        }
    }

    /**
     * @Method Name: beforeUpdate
     * @Input: List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap
     * @Description: Validates LoanRequest__c records before update.
     */
    public void beforeUpdate(List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap) {
        for (LoanRequest__c req : newRecords) {
            LoanRequest__c oldRec = oldMap.get(req.Id);

            // Prevent status regression (e.g., Approved -> Draft)
            if (oldRec.LoanStatus__c == 'Approved' && req.LoanStatus__c == 'Draft') {
                req.LoanStatus__c = oldRec.LoanStatus__c;
            }
        }
    }

    /**
     * @Method Name: afterInsert
     * @Input: List<LoanRequest__c> newRecords
     * @Description: Executes post-insert automation such as audit logging.
     */
    public void afterInsert(List<LoanRequest__c> newRecords) {
        List<Audit__c> audits = new List<Audit__c>();

        for (LoanRequest__c req : newRecords) {
            audits.add(new Audit__c(
                RelatedRecordId__c = req.Id,
                Action__c = 'Created',
                Description__c = 'Loan request created',
                ActionDate__c = DateTime.now()
            ));
        }

        insert audits;
    }

    /**
     * @Method Name: afterUpdate
     * @Input: List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap
     * @Description: Logs changes such as status updates.
     */
    public void afterUpdate(List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap) {
        List<Audit__c> audits = new List<Audit__c>();

        for (LoanRequest__c req : newRecords) {
            LoanRequest__c oldRec = oldMap.get(req.Id);

            // Log status changes
            if (req.LoanStatus__c != oldRec.LoanStatus__c) {
                audits.add(new Audit__c(
                    RelatedRecordId__c = req.Id,
                    Action__c = 'Status Changed',
                    Description__c = 'Status changed from ' + oldRec.LoanStatus__c + ' to ' + req.LoanStatus__c,
                    ActionDate__c = DateTime.now()
                ));
            }
        }

        if (!audits.isEmpty()) {
            insert audits;
        }
    }
}
