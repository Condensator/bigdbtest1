CREATE TYPE [dbo].[AssumptionThirdPartyRelationship] AS TABLE(
	[RelationshipPercentage] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[ThirdPartyRelationshipId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
