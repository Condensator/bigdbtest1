CREATE TYPE [dbo].[DecisionTableParameter] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserFriendlyName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DataType] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[DirectionOfUse] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ValueExpression] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemDefined] [bit] NOT NULL,
	[EntityId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
