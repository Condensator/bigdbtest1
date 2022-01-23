SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetConsentExpiryReport]
(
	@PartyType NVARCHAR(16),	
	@ConsentExpiryDate NVARCHAR(500),
	@PartyName NVARCHAR(500) = '',
	@ConsentCaptureMode NVARCHAR(50) = null, 
	@ConsentType NVARCHAR(200) = null,	
	@IncludeContacts BIT = 0,
	@AllParties BIT = 0,
	@PartyId BIGINT = 0
)
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON	

	DECLARE @ExpiryDate DATE
	-- Set @ConsentCaptureMode
	declare @ConsentCaptureModes table
	(
		ConsentCaptureMode NVARCHAR(16)
	)

	if(@ConsentCaptureMode = 'Verbal,Document,Email')
	Begin
		insert into @ConsentCaptureModes(ConsentCaptureMode) ( Select value from string_split(@ConsentCaptureMode,',') )
	End
	Else if(@ConsentCaptureMode IS NOT NULL )
	Begin
		insert into @ConsentCaptureModes values(@ConsentCaptureMode)
	End 
	
	declare @ConsentTypes table
	(
		ConsentType NVARCHAR(200)
	)

	if(@ConsentType IS NOT NULL)
	Begin
		insert into @ConsentTypes values(@ConsentType)
	End
	Else
	Begin
		insert into @ConsentTypes(ConsentType) ( Select distinct Title from Consents )
	End	

	-- Set EntityTypes/PartyTypes
	declare @PartyTypes table
	(
		PartyType NVARCHAR(16)
	)

	if(@PartyType = 'AllPartyTypes' and @AllParties = 1)
	Begin
		insert into @PartyTypes(PartyType) ( Select distinct EntityType from ConsentConfigs where EntityType not like '%Contact%')
	End
	else if(@PartyType = 'AllPartyTypes' and @AllParties = 0)
	Begin
		insert into @PartyTypes(PartyType) ( Select distinct cd.EntityType from PartyConsentDetails pcd join ConsentDetails cd on pcd.ConsentDetailId = cd.Id where pcd.PartyId = @PartyId)
	End
	Else
	Begin
		insert into @PartyTypes values(@PartyType)
	End

	if(@IncludeContacts = 1)
	Begin
	    insert into @PartyTypes(PartyType) (Select concat(PartyType,'Contact') from @PartyTypes )		
	End

	
	SELECT @ExpiryDate = @ConsentExpiryDate
	
	--Output for ExpiryDate < @ConsentExpiryDate AND Output for ExpiryDate >= @ConsentExpiryDate

	Select distinct cd.Id, cc.EntityType, 
	Case when cc.EntityType like '%Contact%' 
	Then pc.FullName + '	( '+ replace(cd.EntityType,'Contact',', ') + partyContactParentParty.PartyName + ' )'
	Else p.PartyName 
	End as PartyName, 
	c.Title as ConsentType, cd.ExpiryDate, c.ConsentCaptureMode,
	Case when cd.DocumentInstanceId is null 
	Then 'No' Else 'Yes' End as DocumentAttached,
	CASE WHEN(cd.ExpiryDate < GETDATE()) THEN 'True'
	ELSE 'False'
	END 'IsConsentAlreadyExpired' 
 	,DATEADD(MONTH,1,@ExpiryDate) 'ExpiryDateNextMonth' 
	from [ConsentDetails] cd 
	inner join [ConsentConfigs] cc on cd.ConsentConfigId = cc.Id
	inner join [Consents] c on cc.ConsentId = c.Id 
	left join [PartyConsentDetails] pcd on cd.Id = pcd.ConsentDetailId 
	left join [Parties] p on p.Id = pcd.PartyId
	left join  [PartyContactConsentDetails] pccd on cd.Id = pccd.ConsentDetailId 
	left join  [PartyContacts] pc on pc.Id = pccd.PartyContactId and pc.IsActive = 1
	left join [Parties] partyContactParentParty on pc.PartyId = partyContactParentParty.Id
	where cd.EntityType in (Select PartyType from @PartyTypes) 
	and cd.ExpiryDate <= @ExpiryDate
	and @PartyName like Case when @AllParties = 0 Then ( Case when cc.EntityType like '%Contact%' 
	Then (select PartyName from Parties where Id = pc.PartyId)
	Else p.PartyName
	End )
	Else '%' End
	and c.ConsentCaptureMode in ( Select ConsentCaptureMode from @ConsentCaptureModes )
	and c.Title in ( Select ConsentType from @ConsentTypes )
	and  cd.IsActive = 1
	and cd.ConsentStatus = 'Approved'
	order by cd.ExpiryDate, PartyName
	
END

GO
