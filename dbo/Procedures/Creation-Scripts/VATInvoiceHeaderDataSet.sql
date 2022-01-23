SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--EXEC VATInvoiceHeaderDataSet @InvoiceId=54982--43533
CREATE PROCEDURE [dbo].[VATInvoiceHeaderDataSet] 
(
	@InvoiceId BIGINT
)
AS
BEGIN
	DECLARE @ContractId BIGINT, @Key NVARCHAR(100)

	SET @Key = N'M4WHMOVTTT74UP6EL71GWMU4NTXQLLN5' --Tech Debt - Configure to store it in table refer Encrypt/Decrypt document

	select TOP 1 @ContractId = R.EntityId from ReceivableInvoices RI
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
	JOIN ReceivableDetails RD ON RD.Id = RID.ReceivableDetailId
	JOIN Receivables R ON R.Id = RD.ReceivableId
	WHERE RI.Id = @InvoiceId AND R.EntityType = 'CT'

	IF @ContractId IS NULL
	BEGIN
		RAISERROR (N'Could not find the Contract for the InvoiceId : %d', 10, 1,@InvoiceId);
	END

	DECLARE @CustomerId BIGINT, @LeaseFinanceId BIGINT, @LastUpdatedByUser NVARCHAR(200) = ''
	, @InvoiceNumber NVARCHAR(100) = '', @LeaseNumber NVARCHAR(200) = '', @InvoiceDescription NVARCHAR(200) = '', @InvoiceRunDate NVARCHAR(100) = ''
	, @SignatoryNumber NVARCHAR(200) = ''

	SELECT TOP 1 @LeaseFinanceId = LF.Id, @CustomerId = LF.CustomerId
	, @LastUpdatedByUser = CONCAT(U.FirstName,' ', U.LastName), @LeaseNumber = C.SequenceNumber
	, @SignatoryNumber = U.SignatureNumber --Uncomment once implemented
	FROM LeaseFinances LF
	JOIN Contracts C ON C.Id = LF.ContractId
	JOIN Users U ON ISNULL(LF.UpdatedById,LF.CreatedById) = U.Id
	WHERE LF.ContractId = @ContractId AND LF.IsCurrent = 1

	SELECT @InvoiceNumber = Number , @InvoiceRunDate = CONCAT(DATEPART(day,InvoiceRunDate),'.',DATEPART(month,InvoiceRunDate),'.',DATEPART(year,InvoiceRunDate))
	FROM ReceivableInvoices WHERE Id = @InvoiceId
	
	SELECT 
	TOP 1  @InvoiceDescription = CASE 
	WHEN RC.IsVATInvoice = 1 THEN N'Ф А К Т У Р А' ELSE N'СМЕТКА за дължима сума' END
	FROM ReceivableInvoices RI
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId AND RID.IsActive = 1
	JOIN ReceivableDetails RD on RD.Id = RID.ReceivableDetailId AND RD.IsActive = 1
	JOIN Receivables R ON R.Id = RD.ReceivableId AND R.IsActive = 1
	JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
	WHERE RI.Id = @InvoiceId
	ORDER BY R.Id DESC

	DECLARE @PrimaryLesseeName NVARCHAR(400) = '', @PrimaryLesseeBillingAddress NVARCHAR(1000) = '', @PrimaryLesseeMainAddress NVARCHAR(1000) = ''
	, @EGNorEIK NVARCHAR(100) = '', @VATRegistrationNumber NVARCHAR(200) = ''
	,@BranchAddress NVARCHAR(800) = '',@BranchName NVARCHAR(400) = '', @EIKBranch NVARCHAR(200) = '', @PledgeBank NVARCHAR(100) = '', @PledgeBankBIC NVARCHAR(100) = '', @PledgeBankAccount NVARCHAR(100) = '', @BranchVATRegistration NVARCHAR(200) = '', @BranchCity NVARCHAR(100) = '', @SignatoryUserName NVARCHAR(200) = '', @GLJournalNumbers NVARCHAR(200) = ''

	SELECT TOP 1 
	@PrimaryLesseeName = 
	CASE 
		WHEN P.IsSoleProprietor = 1 or P.IsCorporate = 0 THEN P.FirstName +' '+P.MiddleName+ ' '+P.LastName+' '+BT.Name
		WHEN P.IsCorporate = 0 THEN P.FirstName +' '+P.MiddleName+ ' '+P.LastName
		ELSE P.CompanyName +' '+BT.Name END,
	@EGNorEIK = CAST(dbo.Decrypt('nvarchar', P.UniqueIdentificationNumber_CT,@Key) AS NVARCHAR(200)),
	@VATRegistrationNumber = 
	CASE 
		WHEN P.IsSoleProprietor = 1 or P.IsCorporate = 0 THEN '' ELSE P.VATRegistration END
	FROM Parties P
	JOIN Customers C ON C.Id = P.Id
	JOIN BusinessTypes BT ON BT.Id = C.BusinessTypeId
	WHERE C.Id = @CustomerId

	SELECT 
	TOP 1 
	@PrimaryLesseeBillingAddress = 
		CONCAT(CASE WHEN C.LongName IS NOT NULL THEN N'Държ. '+ C.LongName+', ' ELSE ISNULL(N'Държ. '+ CC.LongName+',','') END
		,CASE WHEN S.LongName IS NOT NULL THEN N'обл. '+S.LongName+', ' ELSE ISNULL(N'обл. '+ SS.LongName+',','') END
		,CASE WHEN PA.City IS NOT NULL THEN N'общ. '+PA.City+', ' ELSE '' END
		,CASE WHEN PA.Settlement IS NOT NULL THEN PA.Settlement+', ' ELSE '' END) +
	CASE WHEN S.LongName IS NOT NULL
	THEN 
		CONCAT(
		CASE WHEN PA.AddressLine1 IS NOT NULL THEN PA.AddressLine1 + ', ' ELSE '' END
		,CASE WHEN PA.AddressLine2 IS NOT NULL THEN  N'№ '+PA.AddressLine2+', ' ELSE '' END
		,CASE WHEN PA.AddressLine3 IS NOT NULL THEN  N'вх. '+PA.AddressLine3+ ', ' ELSE '' END
		,CASE WHEN PA.Neighborhood IS NOT NULL THEN  N'ет. '+PA.Neighborhood+', ' ELSE '' END
		,CASE WHEN PA.SubdivisionOrMunicipality IS NOT NULL THEN  N'ап. '+PA.SubdivisionOrMunicipality ELSE '' END)
	ELSE 
		CONCAT(
		CASE WHEN PA.HomeAddressLine1 IS NOT NULL THEN PA.HomeAddressLine1 + ', ' ELSE '' END
		,CASE WHEN PA.HomeAddressLine2 IS NOT NULL THEN  N'№ '+PA.HomeAddressLine2+', ' ELSE '' END
		,CASE WHEN PA.HomeAddressLine3 IS NOT NULL THEN  N'вх. '+PA.HomeAddressLine3+ ', ' ELSE '' END
		,CASE WHEN PA.HomeNeighborhood IS NOT NULL THEN  N'ет. '+PA.HomeNeighborhood+', ' ELSE '' END
		,CASE WHEN PA.HomeSubdivisionOrMunicipality IS NOT NULL THEN  N'ап. '+PA.HomeSubdivisionOrMunicipality ELSE '' END)
	END

	FROM PartyContacts PC
	JOIN PartyContactTypes PCT ON PCT.PartyContactId = PC.Id AND PCT.IsActive = 1
	JOIN PartyAddresses PA ON PA.Id = PC.MailingAddressId AND PA.IsActive = 1
	LEFT JOIN States S On S.Id = PA.StateId
	LEFT JOIN States SS On SS.Id = PA.HomeStateId
	LEFT JOIN Countries C ON C.Id = S.CountryId
	LEFT JOIN Countries CC ON CC.Id = SS.CountryId
	WHERE PC.PartyId = @CustomerId AND PCT.ContactType = 'Billing' AND PC.IsActive = 1
	
	--Remove last , if any
	SET @PrimaryLesseeBillingAddress =  
	CASE WHEN charindex(',', reverse(@PrimaryLesseeBillingAddress)) = 2
	THEN STUFF(@PrimaryLesseeBillingAddress, LEN(@PrimaryLesseeBillingAddress), 1, '') ELSE @PrimaryLesseeBillingAddress END

	SELECT 
	TOP 1 
	@PrimaryLesseeMainAddress = 
		CONCAT(CASE WHEN C.LongName IS NOT NULL THEN N'Държ. '+ C.LongName+', ' ELSE ISNULL(N'Държ. '+ CC.LongName+',','') END
		,CASE WHEN S.LongName IS NOT NULL THEN N'обл. '+S.LongName+', ' ELSE ISNULL(N'обл. '+ SS.LongName+',','') END
		,CASE WHEN PA.City IS NOT NULL THEN N'общ. '+PA.City+', ' ELSE '' END
		,CASE WHEN PA.Settlement IS NOT NULL THEN PA.Settlement+', ' ELSE '' END) +
	CASE WHEN S.LongName IS NOT NULL
	THEN 
		CONCAT(
		CASE WHEN PA.AddressLine1 IS NOT NULL THEN PA.AddressLine1 + ', ' ELSE '' END
		,CASE WHEN PA.AddressLine2 IS NOT NULL THEN  N'№ '+PA.AddressLine2+', ' ELSE '' END
		,CASE WHEN PA.AddressLine3 IS NOT NULL THEN  N'вх. '+PA.AddressLine3+ ', ' ELSE '' END
		,CASE WHEN PA.Neighborhood IS NOT NULL THEN  N'ет. '+PA.Neighborhood+', ' ELSE '' END
		,CASE WHEN PA.SubdivisionOrMunicipality IS NOT NULL THEN  N'ап. '+PA.SubdivisionOrMunicipality ELSE '' END)
	ELSE 
		CONCAT(
		CASE WHEN PA.HomeAddressLine1 IS NOT NULL THEN PA.HomeAddressLine1 + ', ' ELSE '' END
		,CASE WHEN PA.HomeAddressLine2 IS NOT NULL THEN  N'№ '+PA.HomeAddressLine2+', ' ELSE '' END
		,CASE WHEN PA.HomeAddressLine3 IS NOT NULL THEN  N'вх. '+PA.HomeAddressLine3+ ', ' ELSE '' END
		,CASE WHEN PA.HomeNeighborhood IS NOT NULL THEN  N'ет. '+PA.HomeNeighborhood+', ' ELSE '' END
		,CASE WHEN PA.HomeSubdivisionOrMunicipality IS NOT NULL THEN  N'ап. '+PA.HomeSubdivisionOrMunicipality ELSE '' END)
	END
	FROM PartyContacts PC
	JOIN PartyContactTypes PCT ON PCT.PartyContactId = PC.Id AND PCT.IsActive = 1
	JOIN PartyAddresses PA ON PA.Id = PC.MailingAddressId AND PA.IsActive = 1
	LEFT JOIN States S On S.Id = PA.StateId
	LEFT JOIN States SS On SS.Id = PA.HomeStateId
	LEFT JOIN Countries C ON C.Id = S.CountryId
	LEFT JOIN Countries CC ON CC.Id = SS.CountryId
	WHERE PC.PartyId = @CustomerId AND PCT.ContactType = 'Main' AND PC.IsActive = 1

	SET @PrimaryLesseeMainAddress =  
	CASE WHEN charindex(',', reverse(@PrimaryLesseeMainAddress)) = 2
	THEN STUFF(@PrimaryLesseeMainAddress, LEN(@PrimaryLesseeMainAddress), 1, '') ELSE @PrimaryLesseeMainAddress END

	SELECT 
	TOP 1 
	@BranchName = CASE WHEN B.IsHeadquarter = 1 THEN LE.Name ELSE CONCAT(LE.Name,' ', B.BranchName) END
	, @EIKBranch = CAST(dbo.Decrypt('nvarchar', B.EIKNumber_CT,@Key) AS NVARCHAR(200))--Enable when decrypt works
	,@BranchVATRegistration = B.VatRegistrationNumber
	FROM LeaseFinances LF
	JOIN LegalEntities LE ON LE.Id = LF.LegalEntityId
	JOIN Branches B ON B.Id = LF.BranchId
	JOIN BranchAddresses BA ON BA.BranchId = B.Id
	WHERE LF.Id = @LeaseFinanceId

	SELECT 
	TOP 1 
	@BranchAddress = 
		CONCAT(CASE WHEN C.LongName IS NOT NULL THEN N'Държ. '+ C.LongName+', ' ELSE '' END
		,CASE WHEN S.LongName IS NOT NULL THEN N'обл. '+S.LongName+', ' ELSE '' END
		,CASE WHEN BA.City IS NOT NULL THEN N'общ. '+BA.City+', ' ELSE '' END
		,CASE WHEN BA.AddressLine1 IS NOT NULL THEN BA.AddressLine1 ELSE '' END)
	, @BranchCity = CONCAT(N'Държ. ', C.LongName)
	FROM LeaseFinances LF
	JOIN LegalEntities LE ON LE.Id = LF.LegalEntityId
	JOIN Branches B ON B.Id = LF.BranchId
	JOIN BranchAddresses BA ON BA.BranchId = B.Id
	JOIN States S On S.Id = BA.StateId
	JOIN Countries C ON C.Id = S.CountryId
	WHERE LF.Id = @LeaseFinanceId

	SELECT 
	TOP 1 @PledgeBank = Bank, @PledgeBankBIC = BIC, @PledgeBankAccount = BankAccountBGN
	FROM ContractPledges CP
	WHERE CP.ContractId = @ContractId AND CP.IsActive = 1
	
	SELECT 
	@GLJournalNumbers = ISNULL(STRING_AGG(RGL.GLJournalId,','),'')
	FROM ReceivableInvoices RI
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId AND RID.IsActive = 1
	JOIN ReceivableDetails RD on RD.Id = RID.ReceivableDetailId AND RD.IsActive = 1
	JOIN Receivables R ON R.Id = RD.ReceivableId AND R.IsActive = 1
	JOIN ReceivableGLJournals RGL ON RGL.ReceivableId = R.Id
	WHERE RI.Id = @InvoiceId

	SET @GLJournalNumbers =  
	CASE WHEN charindex(',', reverse(@GLJournalNumbers)) = 1
	THEN STUFF(@GLJournalNumbers, LEN(@GLJournalNumbers), 1, '') ELSE @GLJournalNumbers END

	SELECT 
	@GLJournalNumbers = @GLJournalNumbers +ISNULL(STRING_AGG(RGL.GLJournalId,','),'')
	FROM ReceivableInvoices RI
	JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId AND RID.IsActive = 1
	JOIN ReceivableDetails RD on RD.Id = RID.ReceivableDetailId AND RD.IsActive = 1
	JOIN Receivables R ON R.Id = RD.ReceivableId AND R.IsActive = 1
	JOIN ReceivableTaxes RT ON RT.ReceivableId = R.Id
	JOIN ReceivableTaxGLs RGL ON RGL.ReceivableTaxId = RT.Id
	WHERE RI.Id = @InvoiceId

	SELECT 
	--Left Box
	@PrimaryLesseeName PrimaryLesseeName
	, @PrimaryLesseeBillingAddress PrimaryLesseeBillingAddress
	, @PrimaryLesseeMainAddress PrimaryLesseeMainAddress
	, @EGNorEIK EGNorEIK
	, @VATRegistrationNumber VATRegistrationNumber
	--Right box
	, @BranchName BranchName
	, @BranchAddress BranchAddress
	, @EIKBranch EIKBranch
	, @BranchVATRegistration BranchVATRegistration
	, @LastUpdatedByUser LastUpdatedByUser
	, @PledgeBank PledgeBank
	, @PledgeBankBIC PledgeBankBIC
	, @PledgeBankAccount PledgeBankAccount
	, @LeaseNumber LeaseNumber
	, @BranchCity BranchCity
	, @InvoiceNumber InvoiceNumber
	, @InvoiceDescription InvoiceDescription
	, @InvoiceRunDate InvoiceRunDate
	, @SignatoryUserName SignatoryUserName
	, @SignatoryNumber SignatoryNumber
	, @GLJournalNumbers GLJournalNumbers
END

GO
