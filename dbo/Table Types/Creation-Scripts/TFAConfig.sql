CREATE TYPE [dbo].[TFAConfig] AS TABLE(
	[OTPAlogorithim] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OTPType] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClientKeyLength] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPLength] [int] NOT NULL,
	[FailureCounter] [int] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
