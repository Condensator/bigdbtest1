SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetCustomerThirdPartyRelationshipsForCollectionDashboard] (
    @CustomerId BIGINT,
	@PartyContactTypeMain NVarChar(21),
	@BusinessUnitBusinessStartTime  Time,
	@BusinessUnitBusinessEndTime    Time,
	@BusinessUnitTimeZone NVARCHAR(40),
	@BusinessUnitTimeZoneAbbreviation NVARCHAR(5),
	@DNDText NVARCHAR(10),
	@StartingRowNumber INT,
	@EndingRowNumber INT,
	@OrderBy NVARCHAR(6) = NULL,
	@OrderColumn NVARCHAR(MAX) = NULL,
	@WHEREClause NVARCHAR(MAX) = ''
)
AS 
BEGIN 

SET NOCOUNT ON;

   CREATE TABLE #ThirdPartiesInfo
   (
     Id                               BIGINT IDENTITY(1,1) PRIMARY KEY,
	 CustomerThirdPartyRelationshipId BIGINT,
	 ThirdPartyId					  BIGINT,
     ContactSortingOrder              BIGINT,
	 ContactName					  NVarChar(250),
	 PhoneNumber1                     NVarChar(15),
	 PhoneNumber2                     NVarChar(15),
	 MobilePhoneNumber                NVarChar(15),
	 EMailId                          NVarChar(70),
	 PartyContactLocalTime   		  NVARCHAR(max),
	 BusinessUnitLocalTime   		  NVARCHAR(max),	 
	 PartyContactTimeZoneAbbreviation NVarChar(5),
	 PartyContactId                   BIGINT,
	 RowNumber				          BIGINT NULL,	
	 PartyContactBusinessStartTime		TIME,
	 PartyContactBusinessEndTime		TIME,
	 ConsiderBusinessUnitTimeZone       BIT,
	 BusinessStartTime					TIME NULL,
	 BusinessEndTime					TIME NULL,
	 LocalTime   		              NVARCHAR(max) NULL,
	 TimeZoneAbbreviation             NVarChar(5) NULL
   );

   INSERT INTO #ThirdPartiesInfo
   SELECT  
    CustomerThirdPartyRelationships.Id CustomerThirdPartyRelationshipId,
    CustomerThirdPartyRelationships.ThirdPartyId,
	CASE WHEN PartyContactTypes.ContactType = @PartyContactTypeMain THEN 1 ELSE 2 END ContactSortingOrder,
	PartyContacts.FullName,
	PartyContacts.PhoneNumber1,
	PartyContacts.PhoneNumber2,
	PartyContacts.MobilePhoneNumber,
	PartyContacts.EMailId,
	FORMAT(SYSDATETIMEOFFSET() AT TIME ZONE TimeZones.Name ,'hh:mm tt') PartyContactLocalTime,
	FORMAT(SYSDATETIMEOFFSET() AT TIME ZONE @BusinessUnitTimeZone ,'hh:mm tt') BusinessUnitLocalTime,
	TimeZones.Abbreviation PartyContactTimeZoneAbbreviation,
	PartyContacts.Id PartyContactId,
	NULL,
	CAST(PartyContacts.BusinessStartTimeInHours AS NVARCHAR) + ':' + CAST(PartyContacts.BusinessStartTimeInMinutes AS NVARCHAR) + ':00' AS PartyContactBusinessStartTime,
	CAST(PartyContacts.BusinessEndTimeInHours AS NVARCHAR) + ':' + CAST(PartyContacts.BusinessEndTimeInMinutes AS NVARCHAR) + ':00' AS PartyContactBusinessEndTime,
	CASE WHEN 
		((PartyContacts.BusinessStartTimeInHours = 0 AND PartyContacts.BusinessStartTimeInMinutes = 0 AND
		PartyContacts.BusinessEndTimeInHours = 0 AND PartyContacts.BusinessEndTimeInMinutes = 0 ) OR PartyContacts.TimeZoneId IS NULL)
	THEN 1 ELSE 0 END ConsiderBusinessUnitTimeZone,
	NULL,
	NULL,
	NULL,
	NULL
   FROM  CustomerThirdPartyRelationships 
   LEFT JOIN PartyContacts ON CustomerThirdPartyRelationships.[ThirdPartyId] = PartyContacts.PartyId 
   LEFT JOIN PartyContactTypes  ON PartyContacts.Id = PartyContactTypes.PartyContactId
   LEFT JOIN TimeZones ON PartyContacts.TimeZoneId = TimeZones.Id
   WHERE CustomerThirdPartyRelationships.CustomerId = @CustomerId 
   AND CustomerThirdPartyRelationships.IsActive=1 
   AND (PartyContacts.Id IS NULL OR PartyContacts.IsActive=1)
   AND (PartyContactTypes.Id IS NULL OR  PartyContactTypes.IsActive=1)  

   UPDATE #ThirdPartiesInfo 
	SET LocalTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitLocalTime ELSE PartyContactLocalTime END),
	    BusinessStartTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitBusinessStartTime ELSE PartyContactBusinessStartTime END),
        BusinessEndTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitBusinessEndTime ELSE PartyContactBusinessEndTime END),
		TimeZoneAbbreviation = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitTimeZoneAbbreviation ELSE PartyContactTimeZoneAbbreviation END)

   UPDATE #ThirdPartiesInfo
   SET RowNumber=  row_num
   FROM #ThirdPartiesInfo 
   JOIN 
   (
      select
	   Id
	   ,ROW_NUMBER() OVER (
	   partition by ThirdPartyId
	   ORDER BY ThirdPartyId,ContactSortingOrder,PartyContactId 
      ) row_num
      from #ThirdPartiesInfo 
   ) AS OderedThirdParty ON #ThirdPartiesInfo.Id= OderedThirdParty.Id  
    	
      ------------- DYNAMIC QUERY ----------	
   DECLARE @SkipCount BIGINT
   DECLARE @TakeCount BIGINT

   SET @SkipCount = @StartingRowNumber - 1;

   SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;
    
  DECLARE @OrderStatement NVARCHAR(MAX) = 'CustomerThirdPartyRelationshipId,ContactSortingOrder,PartyContactId' 
   
  DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + ' 
	
  DECLARE @Count BIGINT = (	
    SELECT  
         COUNT(Id)
    FROM
    #ThirdPartiesInfo
    WHERE '+ @WHEREClause + ' RowNumber = 1
	) ;
	
    SELECT
	    CustomerThirdPartyRelationshipId
	   ,ContactName
	   ,PhoneNumber1
	   ,PhoneNumber2
	   ,MobilePhoneNumber
	   ,EMailId
	    ,CASE  WHEN (ConsiderBusinessUnitTimeZone = 1 OR (CAST(LocalTime AS Time) BETWEEN BusinessStartTime AND  BusinessEndTime))
         THEN LocalTime + '' '' + ISNULL(TimeZoneAbbreviation, '''')  
         ELSE LocalTime + '' '' + ISNULL(TimeZoneAbbreviation, '''')  + @DNDText END LocalTime 
	   ,CONVERT(BIT,CASE  WHEN  CAST(LocalTime AS Time) BETWEEN BusinessStartTime AND  BusinessEndTime
         THEN 0
         ELSE 1 END) IsDND	
	   ,CONVERT(BIT, CASE WHEN ConsiderBusinessUnitTimeZone = 0 THEN 1 ELSE 0 END) HasTimeZone
	   ,@Count TotalRecords
    FROM 
	  #ThirdPartiesInfo
	WHERE '+ @WHEREClause + ' RowNumber = 1
	ORDER BY '+ @OrderStatement + 
	CASE WHEN @EndingRowNumber > 0
	     THEN
	        ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;' 
         ELSE 
		    ';'  
	END
	
    EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT,@DNDText NVARCHAR(10)',@TakeCount,@SkipCount,@DNDText  

	DROP TABLE #ThirdPartiesInfo
END

GO
