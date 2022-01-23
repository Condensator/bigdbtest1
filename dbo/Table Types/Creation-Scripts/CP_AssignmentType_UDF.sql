CREATE TYPE [dbo].[CP_AssignmentType_UDF] AS TABLE(
	[UDF1Value] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Value] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Value] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Value] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Value] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF1Label] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Label] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Label] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Label] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Label] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AssetID] [bigint] NULL,
	[ContractID] [bigint] NULL,
	[UserId] [bigint] NULL,
	[IsActive] [tinyint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[EntityType] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL
)
GO
