SELECT
	ASP.contractOID,
	LEFT(SF.ID,15) as OpportunityID,
	SF.AccountId,
	SFA.State_ID__c,
	SFC.ID,
	SFC.ssn__C,
	ASPE.OID
FROM 
	[SALESFORCE3].[Cdata].[Salesforce].[Opportunity] SF
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] ASP ON SF.Lease__c = ASP.ContractID
	LEFT OUTER JOIN [SALESFORCE3].[Cdata].[Salesforce].[Account] SFA ON SF.AccountID = SFA.ID
	LEFT OUTER JOIN [SALESFORCE3].[Cdata].[Salesforce].[Contact] SFC ON SF.AccountID = SFC.AccountID
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] ASPE ON REPLACE(SFC.SSN__c,'-','') = ASPE.SSN
WHERE (SF.AccountId IS NOT NULL) AND (ASP.contractOID IS NOT NULL)
ORDER BY ASP.contractOID;
