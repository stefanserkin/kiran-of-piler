trigger deleteOPPteam on OpportunityLineItem (after delete) {
    
    if (Trigger.isDelete) {
        // Create list of Opportunity Team Members to delete
        List<OpportunityTeamMember> otmsToDelete = new List<OpportunityTeamMember>();
        
        // Put all opportunity ids in a set to use in the query
        Set<Id> oppIdSet = new Set<Id>();
        for (OpportunityLineItem oli : Trigger.old) {
            oppIdSet.add(oli.OpportunityId);
        }
        
        // Create a list of OpportunityTeamMembers
        Map<Id, Opportunity> oppyWithOTMsMap = new Map<Id, Opportunity>([
            SELECT Id,
                   (SELECT Id,
                    	   UserId,
            	   		   OpportunityId
                      FROM OpportunityTeamMembers)
              FROM Opportunity
             WHERE Id IN :oppIdSet
        ]);
        
        // Create a map for all opportunities with children line items
        Map<Id, Opportunity> oppyWithOLIsMap = new Map<Id, Opportunity>([
            SELECT Id,
                   (SELECT Id,
                    	   Product_ManagerId__c
                      FROM OpportunityLineItems
                     WHERE Product_ManagerId__c != null)
              FROM Opportunity
             WHERE Id IN :oppIdSet
        ]);
        
        // Loop through line items being deleted
        for (OpportunityLineItem oli : Trigger.old) {
            List<OpportunityTeamMember> relatedOTMs = oppyWithOTMsMap.get(oli.OpportunityId).OpportunityTeamMembers;
            List<OpportunityLineItem> relatedOLIs   = oppyWithOLIsMap.get(oli.OpportunityId).OpportunityLineItems;
            Boolean pmHasAdditionalProducts = false;
            
            // Check to see if product manager id is found in any other line items
            for (OpportunityLineItem relatedOLI : relatedOLIs) {
                if (relatedOLI.Product_ManagerId__c == oli.Product_ManagerId__c) {
                    pmHasAdditionalProducts = true;
                    break;
                }
            }
			
            // If product manager is not found in any other line items,
            // Add the team member with the same userId to a list to delete
            if (!pmHasAdditionalProducts) {
                for (OpportunityTeamMember otm : relatedOTMs) {
                    if (otm.UserId == oli.Product_ManagerId__c) {
                        otmsToDelete.add(otm);
                    }
                }
            }
        }
        
        // Delete opportunity team members
        delete otmsToDelete;
        
    }
}