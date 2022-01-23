CREATE TYPE [dbo].[PlateProfileHistory] AS TABLE(
	[IssuedDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NOT NULL,
	[DoNotRenewRegistration] [bit] NOT NULL,
	[ExpiryDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[LastModifiedDate] [datetimeoffset](7) NOT NULL,
	[LastModifiedReason] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserId] [bigint] NULL,
	[PlateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
