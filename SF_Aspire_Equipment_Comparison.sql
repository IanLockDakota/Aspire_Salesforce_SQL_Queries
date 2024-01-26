SELECT
	Aspire.contractID AS ASPIRE_contractID,
	Aspire.OpportunityID AS ASPIRE_OpportunityID,
	Aspire.SerialNumber AS ASPIRE_SerialNumber,
	Aspire.Description AS ASPIRE_Description,
	Aspire.OriginalCost AS ASPIRE_OriginalCost,
	Salesforce.ID AS SF_EquipID,
	Salesforce.Opportunity__c AS SF_OpportunityID,
	Salesforce.Vin__c AS SF_Vin,
	Salesforce.Name AS SF_Description,
	Salesforce.Cost_Per_Unit__c AS SF_CostPerUnit
FROM
	(SELECT
		eid.EquipmentOid,
		ce.ContractEquipmentOid,
		ce.ContractOid,
		c.contractID,
		OppIDTable.opportunityID,
		eid.SerialNumber,
		e.Description,
		e.OriginalCost
	FROM
		[ASPIRESQL].[AspireDakota].[dbo].[Equipment] e
		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[EquipmentID] eid ON e.EquipmentOid = eid.EquipmentOid
		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[ContractEquipment] ce ON e.EquipmentOid = ce.EquipmentOid
		LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON ce.ContractOid = c.ContractOid
		LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
            FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
            [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
            WHERE GF.oid = 23
			GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid
	WHERE
		OppIDTable.opportunityID IS NOT NULL) as Aspire
	LEFT OUTER JOIN
	(SELECT
		e.ID,
		e.Opportunity__c,
		e.Name,
		e.VIN__c,
		e.Cost_Per_Unit__c,
		o.Contract_ID__c
	FROM
		[SALESFORCE3].[Cdata].[Salesforce].[Equipment__c] e
		LEFT OUTER JOIN [SALESFORCE3].[Cdata].[Salesforce].[Opportunity] o ON e.Opportunity__c = o.id) as Salesforce ON Aspire.contractID = Salesforce.Contract_ID__c AND Aspire.SerialNumber = Salesforce.Vin__c
ORDER BY
	ASPIRE.contractID
