SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UserAuditReport]
(
@UserId BIGINT = NULL,
@LoginName NVARCHAR(50) = NULL,
@FromDate DATETIME2  = NULL,
@ToDate DATETIME2 = NULL
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @TimeZone VARCHAR(50), @TimeStamp NVARCHAR(7), @Length INT;
SET @TimeZone = (SELECT SYSDATETIMEOFFSET());
SET @Length = (SELECT LEN(@TimeZone));
SET @TimeStamp = (Select Substring(@TimeZone, @Length - 5, @Length));
WITH CTE_LastLoginTime
AS (
SELECT U.LoginName,LastLoginDate = MAX(ULA.CreatedTime) FROM Users U
LEFT JOIN UserLoginAudits ULA ON U.ID = ULA.UserId
WHERE U.ApprovalStatus != 'Inactive' AND ULA.IsLoginSuccessful = 1
GROUP BY U.LoginName)
,CTE_TraceEventLog AS
(
SELECT U.Id UserId, ScreenName = TEL.[Transaction],TEL.EventDate
FROM Users U
JOIN TraceEventLogs TEL ON U.ID = TEL.UserId
WHERE (@FromDate IS NULL OR TEL.EventDate >= TODATETIMEOFFSET(@FromDate, @TimeStamp))
AND (@ToDate IS NULL OR TEL.EventDate <= TODATETIMEOFFSET(@ToDate, @TimeStamp))
AND TEL.[Transaction] != 'View'
AND TEL.Form NOT LIKE 'Browse%'
AND TEL.[Transaction] != ''
)
SELECT U.FullName,U.LoginName,cte.LastLoginDate,TEL.ScreenName,TEL.EventDate FROM Users U
LEFT JOIN CTE_TraceEventLog TEL ON U.ID = TEL.UserId
LEFT JOIN CTE_LastLoginTime cte ON U.LoginName = cte.LoginName
WHERE (@UserId IS NULL OR U.Id = @UserId) AND (@LoginName IS NULL OR U.LoginName = @LoginName)
AND U.ApprovalStatus != 'Inactive'
ORDER BY U.LoginName,TEL.EventDate asc
END

GO
