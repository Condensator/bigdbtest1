SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[GetCustomerContactsForCollectionDashboard] (  
 @CustomerId BIGINT,  
 @PartyContactTypeMain NVarChar(21),   
 @PartyContactTypeCollection NVarChar(21), 
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
  
   CREATE TABLE #CustomerContactInfo  
   (  
     Id                               BIGINT IDENTITY(1,1) PRIMARY KEY,  
     ContactSortingOrder              BIGINT,  
	 ContactType                      NVarChar(21),   
	 PartyContactId                   BIGINT,  
	 PartyContactLocalTime   		  NVARCHAR(max),
	 BusinessUnitLocalTime   		  NVARCHAR(max),	 
	 PartyContactTimeZoneAbbreviation NVarChar(5),  
	 RowNumber                        BIGINT NULL,  
	 PartyContactBusinessStartTime		TIME,
	 PartyContactBusinessEndTime		TIME,
	 ConsiderBusinessUnitTimeZone       BIT,
	 BusinessStartTime					TIME NULL,
	 BusinessEndTime					TIME NULL,
	 LocalTime   		              NVARCHAR(max) NULL,
	 TimeZoneAbbreviation             NVarChar(5) NULL
   );  
  
   INSERT INTO #CustomerContactInfo (ContactSortingOrder,ContactType,PartyContactId,
   PartyContactLocalTime,BusinessUnitLocalTime,PartyContactTimeZoneAbbreviation,
   PartyContactBusinessStartTime,PartyContactBusinessEndTime,ConsiderBusinessUnitTimeZone
   ,LocalTime,BusinessStartTime,
   BusinessEndTime,TimeZoneAbbreviation)  
   SELECT    
	CASE WHEN PartyContactTypes.ContactType = @PartyContactTypeCollection THEN 1   
      WHEN PartyContactTypes.ContactType = @PartyContactTypeMain  THEN 2  
   ELSE 3  
    END ContactSortingOrder ,  
 PartyContactTypes.ContactType,   
 PartyContacts.Id PartyContactId,  
 FORMAT(CASE WHEN TimeZones.Name IS NOT NULL 
	       THEN SYSDATETIMEOFFSET() AT TIME ZONE TimeZones.Name 
		   ELSE SYSDATETIMEOFFSET() END 
	   ,'hh:mm tt') PartyContactLocalTime,
	FORMAT(SYSDATETIMEOFFSET() AT TIME ZONE @BusinessUnitTimeZone,'hh:mm tt') BusinessUnitLocalTime,
	TimeZones.Abbreviation PartyContactTimeZoneAbbreviation,
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
   FROM PartyContacts   
   LEFT JOIN PartyContactTypes  on PartyContacts.Id = PartyContactTypes.PartyContactId  
   LEFT JOIN TimeZones ON PartyContacts.TimeZoneId = TimeZones.Id  
   where PartyContacts.PartyId = @CustomerId   
   AND PartyContacts.IsActive = 1  
   AND ( PartyContactTypes.Id IS NULL OR  PartyContactTypes.IsActive=1) 
   
   UPDATE #CustomerContactInfo 
	SET LocalTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN BusinessUnitLocalTime ELSE PartyContactLocalTime END),
	    BusinessStartTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitBusinessStartTime ELSE PartyContactBusinessStartTime END),
        BusinessEndTime = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitBusinessEndTime ELSE PartyContactBusinessEndTime END),
		TimeZoneAbbreviation = (CASE WHEN ConsiderBusinessUnitTimeZone = 1 THEN @BusinessUnitTimeZoneAbbreviation ELSE PartyContactTimeZoneAbbreviation END)
      
   UPDATE #CustomerContactInfo  
   SET RowNumber =  row_num  
   from #CustomerContactInfo   
   JOIN   
   (  
      select  
    Id  
    ,ROW_NUMBER() OVER (  
    partition by PartyContactId  
    ORDER BY ContactSortingOrder,PartyContactId   
      ) row_num  
      from #CustomerContactInfo   
   ) AS OderedThirdParty ON #CustomerContactInfo.Id= OderedThirdParty.Id    
      
      ------------- DYNAMIC QUERY ----------   
   DECLARE @SkipCount BIGINT  
   DECLARE @TakeCount BIGINT  
  
   SET @SkipCount = @StartingRowNumber - 1;  
  
   SET @TakeCount = @EndingRowNumber - @StartingRowNumber + 1;  
      
  DECLARE @OrderStatement NVARCHAR(MAX) = 'ContactSortingOrder,PartyContactId'   
     
  DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '   
   
  DECLARE @Count BIGINT = (   
    SELECT    
         COUNT(Id)  
    FROM  
    #CustomerContactInfo  
    WHERE '+ @WHEREClause + ' RowNumber = 1  
 ) ;  
   
    SELECT  
     PartyContactId  
    ,ContactType
    ,CASE  WHEN (ConsiderBusinessUnitTimeZone = 1 OR (CAST(LocalTime AS Time) BETWEEN BusinessStartTime AND  BusinessEndTime))
         THEN LocalTime + '' '' + ISNULL(TimeZoneAbbreviation, '''')  
         ELSE LocalTime + '' '' + ISNULL(TimeZoneAbbreviation, '''')  + @DNDText END LocalTime 
    ,CONVERT(BIT,CASE  WHEN  CAST(LocalTime AS Time) BETWEEN BusinessStartTime AND  BusinessEndTime  
         THEN 0  
         ELSE 1 END) IsDND  
	,CONVERT(BIT, CASE WHEN ConsiderBusinessUnitTimeZone = 0 THEN 1 ELSE 0 END) HasTimeZone
    ,@Count TotalRecords  
    FROM   
   #CustomerContactInfo  
 WHERE '+ @WHEREClause + ' RowNumber = 1  
 ORDER BY '+ @OrderStatement +   
 CASE WHEN @EndingRowNumber > 0  
      THEN  
         ' OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ;'   
         ELSE   
      ';'    
 END  
   
    EXEC sp_executesql @SelectQuery,N'@TakeCount BIGINT,@SkipCount BIGINT,@DNDText NVARCHAR(10)',@TakeCount,@SkipCount,@DNDText    
  
 DROP TABLE #CustomerContactInfo  
END

GO
