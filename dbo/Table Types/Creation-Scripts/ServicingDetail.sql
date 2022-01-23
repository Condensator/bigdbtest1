CREATE TYPE [dbo].[ServicingDetail] AS TABLE(
	[EffectiveDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsCobrand] [bit] NOT NULL,
	[IsNonNotification] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
