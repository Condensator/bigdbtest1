CREATE TYPE [dbo].[CreditBureauDirectBusinessRequest] AS TABLE(
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsValid] [bit] NOT NULL,
	[CreditBureauBusinessDetailId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
