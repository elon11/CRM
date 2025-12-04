/**
* @Description: Trigger for LoanRequest__c handling before and after DML operations.
* @Created by: Elon Ifrach
* @Created Date: 2025-12-04
*/
trigger LoanRequestTrigger on LoanRequest__c (before insert, before update, after insert, after update) {
    LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();


    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }


        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }


    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }


        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}