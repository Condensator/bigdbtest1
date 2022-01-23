CREATE TYPE [dbo].[CreditApplicationThirdPartyRelationship] AS TABLE(
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[IsCreatedFromCreditApplication] [bit] NOT NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
