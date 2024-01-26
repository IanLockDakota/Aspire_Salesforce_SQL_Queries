SELECT
	SF.ID,
	SF.AccountId,
	ASP.contractOID
FROM 
	[SALESFORCE3].[Cdata].[Salesforce].[Opportunity] SF
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] ASP ON SF.Lease__c = ASP.ContractID
WHERE (SF.AccountId IS NOT NULL) AND (ASP.contractOID IS NOT NULL)
ORDER BY ASP.contractOID