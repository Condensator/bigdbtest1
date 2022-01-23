CREATE TYPE [dbo].[CreditApplicationServicingDetail] AS TABLE(
	[IsLessorServiced] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsLessorCollected] [bit] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsNonNotification] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
