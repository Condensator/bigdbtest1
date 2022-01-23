SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VertexReceivableCodeDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[SundryReceivableCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxReceivableName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsRental] [bit] NOT NULL,
	[TransactionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
