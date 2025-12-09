/**
 * @Description: Trigger for LoanRequest__c handling before and after DML operations.
 *              Handles default values, audit logging, and high amount task creation.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-04
 */
trigger LoanRequestTrigger on LoanRequest__c (after insert, after update) {

    LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
            LoanRequestService.createHighAmountTasks(Trigger.new);
        }
   
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
            LoanRequestService.createHighAmountTasks(Trigger.new);        
            LoanRequestService.sendApprovalEmails(Trigger.new, Trigger.oldMap);
        }
    }
}
