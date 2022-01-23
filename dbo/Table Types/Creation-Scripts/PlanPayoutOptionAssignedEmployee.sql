CREATE TYPE [dbo].[PlanPayoutOptionAssignedEmployee] AS TABLE(
	[EffectiveStartDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveEndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[PlanBasesPayoutId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
