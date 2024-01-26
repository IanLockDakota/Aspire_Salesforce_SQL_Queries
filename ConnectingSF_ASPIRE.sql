------------------Entity, Account, Contact----------------------------------
SELECT
	sfc.Id,
    LEFT(sfc.Id, 15) as ContactID,
	sfc.AccountId,
    LEFT(sfc.AccountId, 15) as AccountID,
	sfa.Opp_ID__c,
    sfc.Name,
    sfc.SSN__c,
	sfc.Account_Record_Type__c,
    sfcc.ModifiedSSN,
	e.ssn,
	e.oid
FROM 
    [SALESFORCE3].[CData].[Salesforce].[Contact] sfc
	LEFT OUTER JOIN
		(SELECT
			sfcb.Id,
			sfcb.SSN__c,
			CASE
				WHEN CHARINDEX('-', SSN__c) > 0 THEN REPLACE(SSN__c, '-', '')
				WHEN CHARINDEX('.', SSN__c) > 0 THEN REPLACE(SSN__c, '.', '')
				ELSE SSN__c
			END AS ModifiedSSN
		FROM 
			[SALESFORCE3].[CData].[Salesforce].[Contact] sfcb
		) AS sfcc ON sfc.id = sfcc.id
	LEFT OUTER JOIN [SALESFORCE3].[CData].[Salesforce].[Account] sfa ON sfc.AccountID = sfa.ID
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Entity] e ON sfcc.ModifiedSSN = e.ssn
WHERE
	((sfc.SSN__c IS NOT NULL) OR (sfc.SSN__c != '--')) AND ((e.ssn IS NOT NULL) OR (e.ssn != ''))
ORDER BY
	sfa.Opp_ID__c







------------------------------Equipment---------------------------------------
